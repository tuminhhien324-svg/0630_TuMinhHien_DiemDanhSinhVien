namespace _0630_TuMinhHien_WebAPI.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public decimal Price { get; set; }
        public string? Image { get; set; }
        public string? Description { get; set; }

        // Mỗi sản phẩm thuộc 1 danh mục (Category)
        public int? CategoryId { get; set; }
        public Category? Category { get; set; }
    }
}
