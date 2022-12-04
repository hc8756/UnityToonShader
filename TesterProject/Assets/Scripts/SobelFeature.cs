using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SobelFeature : ScriptableRendererFeature
{
    public Material sobelMat = null;
    private SobelPass sobelPass;
    private RenderTargetHandle newTarget;
    public override void Create()
    {
        sobelPass = new SobelPass(sobelMat);
        sobelPass.renderPassEvent = RenderPassEvent.BeforeRenderingSkybox;
        newTarget.Init("_RenderTaget");
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (sobelMat == null) {
            Debug.LogWarningFormat("Missing Material");
            return;
        }
        sobelPass.SetSource(renderer.cameraColorTarget);
        renderer.EnqueuePass(sobelPass);
    }

    public class SobelPass : ScriptableRenderPass {
        /*Parameters of blit function*/
        private RenderTargetIdentifier source;
        private RenderTargetIdentifier dest;
        private Material blitMat = null; //this is the material w/ the post processing shader
        RenderTargetHandle tempTex; //will be used to get temporary rt later

        //Constructor
        public SobelPass(Material mat) {
            blitMat = mat;
        }
        public void SetSource(RenderTargetIdentifier id)
        {
            source = id;
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(name: "_SobelPass");

            //post processing code goes here
            RenderTextureDescriptor targDesc = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(tempTex.id, targDesc, FilterMode.Point);
            Blit(cmd, source, tempTex.Identifier(), blitMat, 0);
            Blit(cmd, tempTex.Identifier(), source);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }


}
