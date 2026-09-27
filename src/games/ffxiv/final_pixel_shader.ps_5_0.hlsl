#include "./shared.h"

SamplerState sourceSampler_s : register(s0);
Texture2D<float4> sourceTexture : register(t0);

void main(
        float4 vpos : SV_Position,
        float2 texcoord : TEXCOORD,
    out float4 output : SV_Target0)
{
    float4 color = sourceTexture.Sample(sourceSampler_s, texcoord.xy);

    if (injectedData.toneMapType == 0) {
        color = saturate(color);
    }

    // linearize
    color.rgb = sign(color.rgb) * pow(abs(color.rgb), 2.2f);
    color.a = saturate(color.a);

    if (injectedData.swapChainOutputPreset == renodx::draw::SWAP_CHAIN_OUTPUT_PRESET_HDR10) {
        // Convert the linear BT.709 FP16 proxy to BT.2020/PQ for the 10-bit
        // presentation target. SwapChainPass also applies the configured UI
        // and peak-white scaling before ST.2084 encoding.
        color.rgb = renodx::draw::SwapChainPass(color.rgb, texcoord.xy);
    } else {
        // Preserve the existing scRGB output exactly for A/B testing.
        color.rgb *= injectedData.toneMapUINits / 80.f;
    }

    output.rgba = color;
}
