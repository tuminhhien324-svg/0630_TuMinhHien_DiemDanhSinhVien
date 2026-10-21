using _0630_TuMinhHien_WebAPI.Models;
using _0630_TuMinhHien_WebAPI.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace _0630_TuMinhHien_WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoryApiController : ControllerBase
    {
        private readonly ICategoryRepository _categoryRepository;

        public CategoryApiController(ICategoryRepository categoryRepository)
        {
            _categoryRepository = categoryRepository;
        }

        // GET: api/CategoryApi (Người dùng đã đăng nhập có thể xem danh mục)
        [HttpGet]
        public async Task<IActionResult> GetCategories()
        {
            try
            {
                var categories = await _categoryRepository.GetCategoriesAsync();
                return Ok(categories);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách danh mục", error = ex.Message });
            }
        }

        // GET: api/CategoryApi/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetCategoryById(int id)
        {
            try
            {
                var category = await _categoryRepository.GetCategoryByIdAsync(id);
                if (category == null)
                    return NotFound(new { message = "Không tìm thấy danh mục" });
                return Ok(category);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi tìm danh mục", error = ex.Message });
            }
        }

        // POST: api/CategoryApi (Chỉ Admin mới có quyền Thêm)
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AddCategory([FromBody] Category category)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var created = await _categoryRepository.AddCategoryAsync(category);
                return CreatedAtAction(nameof(GetCategoryById), new { id = created.Id }, created);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi thêm danh mục", error = ex.Message });
            }
        }

        // PUT: api/CategoryApi/{id} (Chỉ Admin mới có quyền Sửa)
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] Category category)
        {
            if (id != category.Id)
                return BadRequest(new { message = "ID danh mục không khớp" });

            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var existing = await _categoryRepository.GetCategoryByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy danh mục để cập nhật" });

                existing.Name = category.Name;
                existing.Description = category.Description;

                await _categoryRepository.UpdateCategoryAsync(existing);
                return Ok(new { message = "Cập nhật danh mục thành công", category = existing });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật danh mục", error = ex.Message });
            }
        }

        // DELETE: api/CategoryApi/{id} (Chỉ Admin mới có quyền Xóa)
        // Khi xóa danh mục: Sản phẩm thuộc danh mục sẽ có CategoryId = null (được cấu hình SetNull trong DbContext)
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            try
            {
                var existing = await _categoryRepository.GetCategoryByIdAsync(id);
                if (existing == null)
                    return NotFound(new { message = "Không tìm thấy danh mục để xóa" });

                await _categoryRepository.DeleteCategoryAsync(id);
                return Ok(new { message = "Xóa danh mục thành công. Các sản phẩm liên quan đã được chuyển về không thuộc danh mục nào." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa danh mục", error = ex.Message });
            }
        }
    }
}
