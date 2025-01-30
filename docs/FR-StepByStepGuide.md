# Guide étape par étape pour implémenter le service.

## Intro / db init.
- Vous pouvez commencer par lancer docker, lancer votre propre instance de base de donnée ou executer le script ```launchPostgresDocker.sh```à la racine du répo:
Soyez sur que vous avez bien lancé le docker engine 😉.
```shell
chmod 775 launchPostgresDocker.sh
./launchPostgresDocker.sh
```
- on peut vérifier que tout est bien initialisé avec le client sql psql:
```shell
psql -h localhost -p 5432 -U postgres -d postgres
```
```sql
SELECT * FROM products;
```
- Je vous invite également à jeter un oeuil au script et au fichier d'initialisation de la database ```/init-scripts/init.sql``` que celui-ci appelle.

## 1. Initialisation du projet.
- Créez un projet type webapi avec la commande dotnet comme suit:
```shell
dotnet new webapi -n GraphQlService
cd GraphQlService
```
- Ajoutez les dépendances nécessaires pour GraphQL, PostgreSQL et Entity FrameworkCore (ou EF Core; requis pour executer les commandes de migrations).
```shell
dotnet add package HotChocolate.AspNetCore
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package HotChocolate.Data.EntityFramework
dotnet tool install --global dotnet-ef
```

## 2. Mise en place de l'ORM (EF Core) la base de données.
- Configurez le contexte EF Core: Créez une classe ```ÀppDbContext``` qui hérite de ```DbContext```.

```shell
mkdir Context
touch Context/AppDbContext.cs
```
```csharp
using Microsoft.EntityFrameworkCore;
namespace GraphQlService.Context;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public virtual required DbSet<Product> Products { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("public");
        base.OnModelCreating(modelBuilder);
    } // We use here the method Fluent API in OnModelCreating to force case correctly as PostgreSql is case sensible.
}

[Table("products")] // You can secure case sensitivity in the db by this way.
public class Product
{
    [Column("id")] // Same her for the columns.
    public int Id { get; set; }
    [Column("name")]
    public string? Name { get; set; }
    [Column("price")]
    public decimal Price { get; set; }
}
```
- Configurez la connection à PostgreSQL dans ```appsettings.json```: Ajoutez votre chaine de connection.
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Username=postgres;Password=mypassword;Database=postgres"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```
- Configurez EF Core dans ```Program.cs```:
```csharp
using Microsoft.EntityFrameworkCore;
using GraphQlService.Context;

builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"));
});
```
- Créez la migration et appliquez à la base de donnée:
```shell
dotnet ef migrations add InitialCreate
#dotnet ef database update #only to sync when you don't already have the db table.
```
- ⚠️ Pas d'inquiétude
```shell
fail: Microsoft.EntityFrameworkCore.Database.Command[20102]
      Failed executing DbCommand (68ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT "MigrationId", "ProductVersion"
      FROM "__EFMigrationsHistory"
      ORDER BY "MigrationId";
Failed executing DbCommand (68ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
SELECT "MigrationId", "ProductVersion"
FROM "__EFMigrationsHistory"
ORDER BY "MigrationId";
```
Cette erreur indique que la requête pour récupérer l'historique des migrations échoue. Cela se produit car la table ```__EFMigrationsHistory``` n'existe pas encore dans la base de données. EF Core créé par sécurité un historique pour chaque migration.

## 3. Ajouter des types GrapQL (Queries, Mutations, Subscriptions).

- **Créez un type GraphQL:** Exemple pour le type de modèle ```Product```
```shell
mkdir Types
touch Types/ProductType.cs
```
```csharp
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
- **Créez un QueryType** pour exposer les données:
```shell
mkdir Query
touch Query/ProductQuery.cs
```
```csharp
using GraphQlService.Context;

namespace GraphQlService.Query
{
    public class Query
    {
        public IQueryable<Product> GetProducts([Service] AppDbContext dbContext) => dbContext.Products;
    }
}
```
- Configurez GraphQL dans ```Program.cs```:
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
- lancez votre application:
```shell
dotnet run
```
rdv sur la page Graphql [Nitro](http://localhost:5089/graphql/) ou ```http://localhost:<port>/graphql``` pour tester votre première query:
```graphql
query {
  products {
    id
    name
    price
  }
}
```
Eh voilà, vous pouvez demander la donnée au format souhaité !

## 4. Tests automatisés et finalisation.