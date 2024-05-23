using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Terrain : MonoBehaviour
{
    public int num_quads;
    public static Mesh viewedModel;

	// Start is called before the first frame update
	void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 position  = Camera.main.transform.position;
		Vector3 scale     = transform.localScale;
		Vector3 mesh_size = viewedModel.bounds.size;

        float   grid_size     =  scale.x * mesh_size.x / ( float )num_quads;
        Vector3 grid_position = position / grid_size;

		transform.position = new Vector3( MathF.Truncate( grid_position.x ), MathF.Truncate( grid_position.x ), MathF.Truncate( grid_position.x ) ) * grid_size;
	}
}
