using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Grass Render Pipeline")]
public class GrassSRP : RenderPipelineAsset
{
	protected override RenderPipeline CreatePipeline()
	{
		return new GrassRP();
	}
}
