using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UIElements;
using static UnityEngine.Rendering.DebugUI;

public class TerrainManager : MonoBehaviour
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

	public static float m_tiling { get; private set; }

	public static Vector3 worldoffset { get; private set; }
	[SerializeField]
	private float height;
	public static float terrain_height { get; private set; }


	private void OnEnable()
	{
		terrain_height = height;
	}

	// Start is called before the first frame update
	void Awake()
    {
		planes = new GameObject[ lods ];

		float scale = 1.0f;
		for ( uint i = 0; i < lods; i++ )
		{
			planes[i] = Instantiate( plane, transform.position, transform.rotation );

			if ( i != 0 ) 
				planes[i].GetComponent<Renderer>().material = far_material;
			
			var loacal_scale = transform.localScale;
			planes[i].transform.localScale = new Vector3( scale * loacal_scale.x, loacal_scale.y, scale * loacal_scale.z );
			planes[i].transform.parent = transform;
			scale *= 2.0f;
		}

		Mesh mesh = plane.GetComponent< MeshFilter >().sharedMesh;

		uint num_indecies = 0;

		for ( int i = 0; i < mesh.subMeshCount; i++ )
			num_indecies += mesh.GetIndexCount( i );

		float width = Mathf.Sqrt( ( float )( num_indecies / 6 ) );
		m_tiling = mesh.bounds.size.x * transform.localScale.x / width * 3.0f;
	}

	// Update is called once per frame
	void Update()
    {
		Camera cam = Camera.main;

		cam.cullingMatrix = Matrix4x4.Ortho(-99999, 99999, -99999, 99999, 0.001f, 99999) *
							Matrix4x4.Translate(Vector3.forward * -99999 / 2f) *
							cam.worldToCameraMatrix;

		Vector3 cam_pos        = cam.GetComponent< CameraController >().m_position;
		Vector3 plane_position = new Vector3( mod( cam_pos.x , m_tiling ), 0.0f, mod( cam_pos.z, m_tiling ) );
		worldoffset           = new Vector3( math.floor( cam_pos.x / m_tiling ) * m_tiling, cam_pos.y, Mathf.Floor( cam_pos.z / m_tiling ) * m_tiling );


		cam.transform.position = new Vector3( plane_position.x, cam.transform.position.y, plane_position.z );

		near_material.SetVector( "u_offset", worldoffset );
		far_material.SetVector( "u_offset", worldoffset );
		near_material.SetFloat( "u_height", terrain_height);
		far_material.SetFloat( "u_height", terrain_height);
	}

	private static float mod( float _num, float _mod )
	{
		float o = _num % _mod;
		return o < 0 ? o	 + _mod : o;
	}

}
