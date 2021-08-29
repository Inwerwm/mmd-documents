#define SDPBR_MATERIAL_VER 100
#include "../../shader/sdPBRMaterialHead.fxsub"

// 周期
// 何秒に1回滴下するか
float periodicity = 3;
// テクスチャが伸びきるまでにかかる時間の1周期中の割合
float stretchTimeRatio = 0.5;
// 最大伸長時の縦方向テクスチャリピート数
float lastRepeat = 10;
// 伸長開始時点のテクスチャリピート数の最大伸長時の数に対する割合
float startRepeatRatio = 10;
// 滴下するテクスチャファイル
#define DropTextureName "../../texture/seal_mmd.png"

// 透過マップ
// MASK_FROM_CODE だと読んでくれないので自分で読む
texture DropTextureMASK < string ResourceName = DropTextureName;>;
sampler DropFX_MaskSamp = sampler_state {
        Texture = <DropTextureMASK>;
        MinFilter = ANISOTROPIC;
        MagFilter = ANISOTROPIC;
        MipFilter = LINEAR;
        MaxAnisotropy = MAX_ANISOTROPY;
        ADDRESSU = WRAP;
        ADDRESSV = WRAP;
};

// UVを変化させて滴下を表現する
int dropTarget = 0;
void Drop(inout float2 uv, float timeOffset, float periodicityOffset, float stretchTimeRatioOffset)
{
    float current              = ftime + timeOffset;
    float thisPeriodicity      = periodicity + periodicityOffset;
    float thisStretchTimeRatio = stretchTimeRatio + stretchTimeRatioOffset;

    // 周期中のどの時点か
    float timeRatio    = current / thisPeriodicity % 1.0;
    // 現在のテクスチャ伸長割合
    float stretchRatio = pow(timeRatio * (1 / thisStretchTimeRatio), 0.2);

    // 現在のテクスチャのリピート数
    float repeat = timeRatio < thisStretchTimeRatio 
                 ? startRepeatRatio / (stretchRatio * startRepeatRatio) * lastRepeat
                 : lastRepeat;
    // 落下開始からの経過時間
    float time   = stretchRatio < 1.0 ? 0 : current % thisPeriodicity - thisStretchTimeRatio * thisPeriodicity;

    if(dropTarget <= uv.x && uv.x < dropTarget + 1)
    {
        uv.y -= 9.8 * time * time;
        uv.y *= repeat;
    }
    dropTarget++;
}

void SetMaterialParam(inout Material m, float3 n, float3 l, float3 Eye, inout float2 uv)
{
    // 表示させたい個数分だけかける
    uv.x *= 4;

    // かけた数だけ関数を呼ぶ
    //        時間,  周期,  伸長);
    Drop(uv,  0.0,  0.0,  0.0);
    Drop(uv,  0.1,  0.1,  0.1);
    Drop(uv,  0.2,  0.2,  0.2);
    Drop(uv, -0.3, -0.3, -0.3);
}

#define BASECOLOR_FROM BASECOLOR_FROM_FILE
#define BASECOLOR_FILE DropTextureName

#define MASK_FROM MASK_FROM_CODE
#define MASK_CODE _Get_Mask
float _Get_Mask(Material m, float3 n, float3 Eye, float2 uv)
{
    // UV座標が [0, 1) の範疇にある場合のみ表示する
    float range = uv.y > 1.0 ? 0 : uv.y < 0 ? 0 : 1;
    // テクスチャの透過度を反映して返す
    return range * tex2D(DropFX_MaskSamp, uv).a;
}

#include "../../shader/sdPBRMaterialTail.fxsub"