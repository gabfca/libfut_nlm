import "lib/github.com/athas/vector/vector"
import "lib/github.com/athas/vector/vspace"

module vector_2 = cat_vector vector_1 vector_1
module vector_4 = cat_vector vector_2 vector_2

module vec4 = vector_4
module vspace4 = mk_vspace vector_4 f32

module fut_nlm =  
{   
    def iota2d n = flatten (map (\y -> map (\x -> (x, y)) (iota n)) (iota n))

    def gaussian_weight(d: f32) (h: f32) = f32.exp ( (-d) / h)

    type lrgba = vec4.vector f32

    let zero_vec =  vec4.from_array( [0.0, 0.0, 0.0, 0.0] :> [vec4.length]f32)
    let one_vec  =  vec4.from_array( [1.0, 1.0, 1.0, 1.0] :> [vec4.length]f32)

    -- This is a view over the lRGBA values and dimensions of an image, or subdivisions of an image.    
    type region [w][h] = { pixs: *[h][w]lrgba }
    
    module region = 
    {   
        def subregion_from_indices [rs] [rs'] (src: region [rs] [rs]) (indices: [rs' * rs'](i64, i64)): region [rs'] [rs'] = { 
            pixs = map (\coords -> src.pixs[coords.0][coords.1]) indices
                   |> unflatten 
        }

        def indices_of_reflection_bounded_subregion (x: i64, y: i64) (rs: i64) (rs': i64): [rs' * rs'](i64, i64) =
            let reflect_coord(coord: i64, max_coord: i64) = 
                if coord < 0 then -coord else if coord >= max_coord then 2 * max_coord - coord - 2 else coord

            let half_rs' = rs' // 2

            in map(\(dy, dx) -> 
                    let ix = reflect_coord ( (x + dx - half_rs'), rs)
                    let iy = reflect_coord ( (y + dy - half_rs'), rs)
                    in (iy, ix)
                ) (iota2d rs')
    }           

    module patchwise =  
    {           

        -- Different patch similarity methods
        module patch_similarity = 
        {
            def euclidean_distance [pw] [ph] (p: [ph * pw]lrgba) (p': [ph * pw]lrgba): f32 =
               map2 (\p_pix p'_pix -> p_pix vspace4.- p'_pix) p p'
                    |> map(vspace4.quadrance)
                    |> reduce (+) 0
        }

        type params = {
            patch_side: i64,
            search_window_side: i64,
            h: f32
        }

        def search_window_iteration [ws] 
            (search_window: region [ws] [ws]) 
            (patch_side: i64)
            (filter_strength: f32) 
        =
            let take_patch_around (x, y) =  
                let patch_indices = region.indices_of_reflection_bounded_subregion (x, y) ws patch_side
                in region.subregion_from_indices search_window patch_indices

            let p = take_patch_around (0, 0)
            let flat_p_pixs = flatten p.pixs

            -- Non-sequentually compute the distance of every patch to the prime patch.
            let iteration_results = map(\(i, j) -> 
                let curr_patch = take_patch_around(i, j)
                
                let distance = patch_similarity.euclidean_distance (flat_p_pixs) (flatten curr_patch.pixs) 
        
                let this_weight = gaussian_weight distance filter_strength
                in (this_weight, vspace4.scale this_weight search_window.pixs[j][i])
            ) ((iota2d (ws)))

            let (weights, patch_colors) = unzip iteration_results

            let sum_patch_colors = reduce_comm (vspace4.+) (zero_vec) (patch_colors) 

            let sum_weight = (reduce (+) 0 weights)
            
            in (vspace4.scale (1/sum_weight) sum_patch_colors)

        def nlm [rs] 
            (src: *region [rs][rs]) 
            (params: params)
        : *region[rs][rs]
        =   
            let iter_at (x, y) = 
                let search_window_indices = region.indices_of_reflection_bounded_subregion (x, y) rs params.search_window_side
                let search_window = region.subregion_from_indices src search_window_indices
                let iter_result = search_window_iteration search_window params.patch_side params.h
                in iter_result

            in src with pixs = map (\(x, y) -> iter_at (x, y)) (iota2d rs) |> unflatten 
    }   

}

open fut_nlm

-- Since this is an entry function we couldn't take an adequately sized input array.
entry libfnlm_patchwise_nlm 
    (channels: []f32) 
    (dim_x: i64) 
    (dim_y: i64) 

    (patch_side: i64)
    (search_window_side: i64)
    (h: f32) = 
    
    -- But we can coerce it to one.
    -- We use `vec4.length` directly here because the type system doesn't resolve that to `4` on its own
    let channels: [ dim_x * dim_x * vec4.length ]f32 = sized ( dim_x * dim_x * vec4.length ) channels

    -- Now that we do have a properly sized array, we can interpret the outer [4]f32s as static-size vectors.
    let src_region = { pixs = map( \row -> map vec4.from_array row ) ( unflatten_3d channels ) }

    --- And finally, perform patchwise non local means denoising on the input region.
    in (fut_nlm.patchwise.nlm src_region {patch_side = patch_side, search_window_side = search_window_side, h = h}).pixs
       |> flatten
       |> map (vec4.to_array)
       |> flatten
---
---

