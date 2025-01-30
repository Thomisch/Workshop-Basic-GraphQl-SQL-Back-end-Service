using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace GraphQlService.Context;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public virtual required DbSet<Product> Products { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("public");
        base.OnModelCreating(modelBuilder);
    }
}

[Table("products")]
public class Product
{
    [Column("id")]
    public int Id { get; set; }
    [Column("name")]
    public string? Name { get; set; }
    [Column("price")]
    public decimal Price { get; set; }
}