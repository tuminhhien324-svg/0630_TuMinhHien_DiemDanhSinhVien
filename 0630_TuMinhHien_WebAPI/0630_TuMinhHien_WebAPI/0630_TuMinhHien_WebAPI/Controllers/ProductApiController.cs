using _0630_TuMinhHien_WebAPI.Models;
using _0630_TuMinhHien_WebAPI.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace _0630_TuMinhHien_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductApiController : ControllerBase
    {
        private readonly IproductRepository _productRepository;

        public ProductApiController(IproductRepository productRepository)
        {
            _productRepository = productRepository;
        }

        // GET: api/ProductApi (Người dùng đã đăng nhập: Admin, Staff, Customer/User đều có thể xem)
        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetProducts()
        {
            try
            {
                var products = await _productRepository.GetProductsAsync();
                return Ok(products);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách sản phẩm", error = ex.Message });
            }
        }

        // GET: api/ProductApi/{id}
        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetProductById(int id)
        {
            try
            {
                var product = await _productRepository.GetProductByIdAsync(id);
                if (product == null)
                    return NotFound(new { message = "Không tìm thấy sản phẩm" });
                return Ok(product);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi tìm sản phẩm", error = ex.Message });
            }
        }

        // POST: api/ProductApi (Admin và Staff có quyền Thêm sản phẩm)
        [HttpPost]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> AddProduct([FromBody] Product product)
        {
            try
            {
                await _productRepository.AddProductAsync(product);
                return CreatedAtAction(nameof(GetProductById), new { id = product.Id }, product);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi thêm sản phẩm", error = ex.Message });
            }
        }

        // PUT: api/ProductApi/{id} (Admin và Staff có quyền Sửa sản phẩm)
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin,Staff")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] Product product)
        {
            try
            {
                if (id != product.Id)
                    return BadRequest(new { message = "ID sản phẩm không khớp" });

                await _productRepository.UpdateProductAsync(product);
                return Ok(new { message = "Cập nhật sản phẩm thành công", product });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật sản phẩm", error = ex.Message });
            }
        }

        // DELETE: api/ProductApi/{id} (Chỉ riêng Admin mới có quyền Xóa sản phẩm)
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            try
            {
                var existing = await _productRepository.GetProductByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy sản phẩm để xóa" });

                await _productRepository.DeleteProductAsync(id);
                return Ok(new { message = "Xóa sản phẩm thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa sản phẩm", error = ex.Message });
            }
        }
    }
}
