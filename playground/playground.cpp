#include "../bind_cpp/libfut_nlm.hpp"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <string_view>

using namespace std::chrono;
using namespace libfut_nlm;

std::int32_t main(int argc, char **argv) 
{   

    {
        stbi_ldr_to_hdr_gamma(1.0f);    
        setvbuf(stdout, NULL, _IONBF, 0);
    }

    assert(argv[1] && "[libfut_nlm:playground] Provide source image path.");

    std::printf("[libfut_nlm:playground] Reading source image %s.\n", argv[1]);
    
    std::int32_t width;
    std::int32_t height;
    std::int32_t comp;
    float *noisy;

    noisy = stbi_loadf(argv[1], &width, &height, &comp, 4);
    assert(noisy && "[libfut_nlm:playground] Couldn't load source image.\n");

    std::vector<std::uint8_t> as_bytes;
    as_bytes.reserve(width * height * 4);

    std::printf("[libfut_nlm:playground] Pre-allocating output memory.\n");
    
    float *denoised = (float *) malloc(sizeof(float) * width * height * comp);

    std::printf("[libfut_nlm:playground] Creating Futhark context.\n");

    FutharkContextWrapper cw;

    region info = {
        .lrgba = noisy,
        .dim_x = static_cast<std::int64_t>(width),
        .dim_y = static_cast<std::int64_t>(height),
    };

    auto t1 = high_resolution_clock::now();
    auto t2 = t1;

    while (true) {
        float h;
        int patch_side, window_side;
        std::printf("\n[libfut_nlm:playground] h ps ws > ");
        scanf("%f %d %d", &h, &patch_side, &window_side);

        t1 = high_resolution_clock::now();
        auto result = patchwise(cw, info, patch_side, window_side, h);
        t2 = high_resolution_clock::now();

        auto time = duration_cast<milliseconds>(t2 - t1);

        for (int i = 0; i < width * height * 4; ++i) {
            auto f = result[i];
            as_bytes.push_back((f >= 1.0 ? 255 : (f <= 0.0 ? 0 : static_cast<int>(std::floor(f * 256.0)))));
        }

        stbi_write_bmp("denoisy.bmp", width, height, 4, as_bytes.data());
        std::printf("\n[libfut_nlm:playground] DONE with: h=%f | ps = %d | ws = %d", h, patch_side, window_side);
        std::cout << "\n[libfut_nlm:playground] t=" << time.count() << "ms\n\n";

        as_bytes.clear();
    }

    stbi_image_free(noisy);

    return 0;
}
