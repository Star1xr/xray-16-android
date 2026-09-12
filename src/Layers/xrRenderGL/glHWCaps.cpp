#include "stdafx.h"
#pragma hdrstop

#include "Layers/xrRender/HWCaps.h"
#include "glHW.h"

namespace xray::render::RENDER_NAMESPACE
{
namespace
{
u32 GetGpuNum()
{
    return 2;
}
}

void CHWCaps::Update()
{
    // ***************** GEOMETRY
#ifdef TOGLES
    geometry_major = 3;
    geometry_minor = 0;
    geometry_profile = "vs_3_0";
#else
    geometry_major = 4;
    geometry_minor = 0;
    geometry_profile = "vs_4_0";
#endif
    geometry.bSoftware = FALSE;
    geometry.bPointSprites = FALSE;
    geometry.bNPatches = FALSE;
    u32 cnt = 256;
    clamp<u32>(cnt, 0, 256);
    geometry.dwRegisters = cnt;
    geometry.dwInstructions = 256;
    geometry.dwClipPlanes = _min(6, 15);
#ifdef TOGLES
    geometry.bVTF = GLAD_GL_VERSION_3_0 && !strstr(Core.Params, "-novtf");
#else
    geometry.bVTF = (GLAD_GL_VERSION_3_0 || GLAD_GL_ARB_texture_float) && !strstr(Core.Params, "-novtf");
#endif

    // ***************** PIXEL processing
#ifdef TOGLES
    raster_major = 3;
    raster_minor = 0;
    raster_profile = "ps_3_0";
#else
    raster_major = 4;
    raster_minor = 0;
    raster_profile = "ps_4_0";
#endif
    // XXX: review this
    raster.dwStages = 15; // Previuos value is 16, but it's out of bounds
    raster.bNonPow2 = TRUE;
    raster.bCubemap = TRUE;
#ifdef TOGLES
    raster.dwMRT_count = 4; // GLES 3.0 guarantees at least 4
#else
    raster.dwMRT_count = 4;
#endif
    // raster.b_MRT_mixdepth		= FALSE;
    raster.b_MRT_mixdepth = TRUE;
    raster.dwInstructions = 256;
    //	TODO: GL: Find a way to detect cache size
    geometry.dwVertexCache = 24;

    // *******1********** Compatibility : vertex shader
    if (0 == raster_major)
        geometry_major = 0; // Disable VS if no PS

    //
    bTableFog = FALSE; // BOOL	(caps.RasterCaps&D3DPRASTERCAPS_FOGTABLE);

    // Detect if stencil available
    bStencil = TRUE;

    // Scissoring
    bScissor = TRUE;

    // Stencil relative caps
    soInc = D3DSTENCILOP_INCRSAT;
    soDec = D3DSTENCILOP_DECRSAT;
    dwMaxStencilValue = (1 << 8) - 1;

    // FFP lights
    max_ffp_lights = 0;

    // DEV INFO

    iGPUNum = GetGpuNum();

    useCombinedSamplers = true;
}
} // namespace xray::render::RENDER_NAMESPACE
