### Non-local means image denoising done efficiently in Futhark.
With special bindings in modern C++.


![Noisy input image.](img/noisy.bmp)
![Denoised output with h=0.32, a patch side of 7 and a search window side 15.](img/output.bmp)


To try backends other than Futhark's CUDA one, edit ``/lib/futhark/make_futhark.sh`` accordingly.
