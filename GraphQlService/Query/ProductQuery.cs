using GraphQlService.Context;

namespace GraphQlService.Query
{
    public class Query
    {
        public IQueryable<Product> GetProducts([Service] AppDbContext dbContext) => dbContext.Products;
    }
}
