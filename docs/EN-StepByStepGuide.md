# Step-by-step guide to implementing the service.

## Intro / db init.
- You can start by launching docker, launching your own database instance or running the ``launchPostgresDocker.sh`` script at the root of the repo:
Make sure you've launched the docker engine 😉.
```shell
chmod 775 launchPostgresDocker.sh
./launchPostgresDocker.sh
```
- you can check that everything has been initialized with the psql sql client:
```shell
psql -h localhost -p 5432 -U postgres -d postgres
```
```sql
SELECT * FROM products;
```
- I also invite you to take a look at the script and the database initialization file ``/init-scripts/init.sql`` that it calls.

## 1. project initialization.
- Create a webapi project with the dotnet command as follows:
```shell
dotnet new webapi -n GraphQlService
cd GraphQlService
```
- Add the necessary dependencies for GraphQL, PostgreSQL and Entity FrameworkCore (or EF Core; required to run migration commands).
```shell
dotnet add package HotChocolate.AspNetCore
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package HotChocolate.Data.EntityFramework
dotnet tool install --global dotnet-ef
```

## 2. Mise en place de l'ORM (EF Core) la base de données.
- Configurez le contexte EF Core : Créez une classe ``ÀppDbContext`` qui hérite de ``DbContext``.

``shell
mkdir Context
touch Context/AppDbContext.cs
```
``csharp
using Microsoft.EntityFrameworkCore ;
namespace GraphQlService.Context ;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public virtual required DbSet<Product> Products { get ; set ; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema(« public ») ;
        base.OnModelCreating(modelBuilder) ;
    } // Nous utilisons ici la méthode Fluent API dans OnModelCreating pour forcer la casse correctement car PostgreSql est sensible à la casse.
}

[Table(« products »)] // Vous pouvez sécuriser la sensibilité à la casse dans la base de données de cette manière.
public class Product
{
    [Column(« id »)] // Même chose pour les colonnes.
    public int Id { get ; set ; }
    [Column(« name »)]
    public string ? Name { get ; set ; }
    [Column(« price »)]
    public decimal Price { get ; set ; }
}
```
- Configure the connection to PostgreSQL in ``appsettings.json``: Add your connection string.
```json
{
  “ConnectionStrings": {
    “DefaultConnection": ”Host=localhost;Port=5432;Username=postgres;Password=mypassword;Database=postgres”
  },
  “Logging": {
    “LogLevel": {
      “Default": ‘Information’,
      “Microsoft.AspNetCore": ”Warning”
    }
  },
  “AllowedHosts": ”*”
}
```
- Configure EF Core in ```Program.cs``:
```csharp
using Microsoft.EntityFrameworkCore;
using GraphQlService.Context;

builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString(“DefaultConnection”));
});
```
- Create the migration and apply to the database:
```shell
dotnet ef migrations add InitialCreate
#dotnet ef database update #only to sync when you don't already have the db table.
```
- ⚠️ No worries
```shell
fail: Microsoft.EntityFrameworkCore.Database.Command[20102]
      Failed executing DbCommand (68ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT “MigrationId”, “ProductVersion”
      FROM “__EFMigrationsHistory”
      ORDER BY “MigrationId”;
Failed executing DbCommand (68ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
SELECT “MigrationId”, “ProductVersion”
FROM “__EFMigrationsHistory”
ORDER BY “MigrationId”;
```

This error indicates that the request to retrieve the migration history has failed. This occurs because the ``__EFMigrationsHistory`` table does not yet exist in the database. EF Core creates a history for each migration.

## 3. Add GrapQL types (Queries, Mutations, Subscriptions).

- Create a GraphQL type:** Example for the ``Product`` model type
```shell
mkdir Types
touch Types/ProductType.cs
``````csharp
using GraphQlService.Context;

namespace GraphQlService.Types
{
    public class ProductType : ObjectType<Product>
    {
        protected override void Configure(IObjectTypeDescriptor<Product> descriptor)
        {
            descriptor.Field(p => p.Id).Type<NonNullType<IdType>>();
            descriptor.Field(p => p.Name).Type<NonNullType<StringType>>();
            descriptor.Field(p => p.Price).Type<NonNullType<DecimalType>>();
        }
    }
}
```
- Create a QueryType** to expose the data:
```shell
mkdir Query
touch Query/ProductQuery.cs
```
csharp
using GraphQlService.Context;

namespace GraphQlService.Query
{
    public class Query
    {
        public IQueryable<Product> GetProducts([Service] AppDbContext dbContext) => dbContext.Products;
    }
}
```
- Configure GraphQL in ``Program.cs``:
```csharp
using GraphQlService.Query;
using GraphQlService.Types;
builder.Services
    .AddGraphQLServer()
    .AddQueryType<Query>()
    .AddType<ProductType>()
    .AddFiltering()
    .AddSorting();

app.MapGraphQL();
```
- launch your application:
```shell
dotnet run
```
go to Graphql [Nitro](http://localhost:5089/graphql/) or http://localhost:<port>/graphql`` to test your first query:
``graphql
query {
  products {
    id
    name
    price
  }
}
```
Now you can request the data in the desired format!

## 4. Automated tests and finalization.