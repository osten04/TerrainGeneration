using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UIElements;
using static UnityEngine.Rendering.DebugUI;

public class GameManager : MonoBehaviour
{
    [SerializeField]
    GameObject plane;

	[SerializeField]
	uint lods;
	
	[SerializeField]
	Material near_material;
	[SerializeField]
	Material far_material;

	private GameObject[] planes;

	// Start is called before the first frame update
	void Start()
    {
		planes = new GameObject[ lods ];

		float scale = 1.0f;
		for ( uint i = 0; i < lods; i++ )
		{
			planes[i] = Instantiate(plane, transform.position, transform.rotation);

			if ( i != 0 ) 
				planes[i].GetComponent<Renderer>().material = far_material;
			
			var loacal_scale = transform.localScale;
			planes[i].transform.localScale = new( scale * loacal_scale.x, 1.0f * loacal_scale.y, scale * loacal_scale.z );
			planes[i].transform.parent = transform;
			scale *= 2.0f;
		}

		//Vector3 cam_pos = Camera.main.transform.position;
		//planes[0].GetComponent<Renderer>().material.SetVector("offset", new(cam_pos.x, 0.0f, cam_pos.z, 0.0f) );
	}

	// Update is called once per frame
	void Update()
    {
		Camera cam = Camera.main;

		cam.cullingMatrix = Matrix4x4.Ortho(-99999, 99999, -99999, 99999, 0.001f, 99999) *
							Matrix4x4.Translate(Vector3.forward * -99999 / 2f) *
							cam.worldToCameraMatrix;

		Vector3 cam_pos = cam.transform.position;

		near_material.SetVector("u_offset", cam_pos);
		far_material.SetVector("u_offset", cam_pos);
	}
}
