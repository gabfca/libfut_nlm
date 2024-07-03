#pragma once


#include <cstdint>
#include <memory>
#include <vector>
#include <iostream>
#include <chrono>

#include "../lib/libfut_nlm.h"

namespace libfut_nlm 
{
    struct FutharkContextWrapper 
    {
    public:
        futhark_context_config *cfg;
        futhark_context *ctx;

        FutharkContextWrapper() {
            this->cfg = futhark_context_config_new();
            this->ctx = futhark_context_new(this->cfg);
        }

        ~FutharkContextWrapper() {
            futhark_context_free(this->ctx);
            futhark_context_config_free(this->cfg);
        }

    };

    struct lRGBA { float r, g, b, a; };

    struct region {
        alignas(8) float *lrgba;
        std::int64_t dim_x;
        std::int64_t dim_y;
    };

    [[nodiscard]] 
    auto patchwise(FutharkContextWrapper &cw, region &img, std::int64_t patch_side, std::int64_t search_window_side, float h) noexcept -> std::unique_ptr<float[]> 
    {
        std::uint64_t size = img.dim_x * img.dim_y * 4;
        
        std::unique_ptr<float[]> out_lrgba(new float[size]);

        auto *in_as_fut_arr = futhark_new_f32_1d(cw.ctx, img.lrgba, img.dim_x * img.dim_y * 4);
        futhark_f32_1d *out_as_fut_arr = futhark_new_f32_1d(cw.ctx, out_lrgba.get(), img.dim_x * img.dim_y * 4);

        futhark_entry_libfnlm_patchwise_nlm(cw.ctx, &out_as_fut_arr, in_as_fut_arr, img.dim_x, img.dim_y, patch_side, search_window_side, h);
        std::int32_t res = futhark_values_f32_1d(cw.ctx, out_as_fut_arr, out_lrgba.get());

        futhark_free_f32_1d(cw.ctx, in_as_fut_arr);
        futhark_free_f32_1d(cw.ctx, out_as_fut_arr);

        return out_lrgba;
    }
}