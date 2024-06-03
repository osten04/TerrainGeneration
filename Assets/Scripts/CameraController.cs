using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    // Start is called before the first frame update
    private Vector3 m_position;
    private Vector3 m_rotation;

    void Start()
    {
        m_position = new Vector3();
		m_rotation = new Vector3();
	}

    // Update is called once per frame
    void Update()
    {
        if (!Application.isFocused)
            return;

		float horizontalInput = Input.GetAxis( "Mouse X" );
		float verticalInput   = Input.GetAxis( "Mouse Y" );

        m_rotation        += new Vector3( -verticalInput, horizontalInput, 0.0f );
		transform.rotation = Quaternion.Euler( m_rotation );

		Vector3 move = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical") ) * Time.deltaTime * 200.0f;

		m_position += Quaternion.AngleAxis(m_rotation.y, Vector3.up) * ( Quaternion.AngleAxis(m_rotation.x, Vector3.right) * move );
        transform.position = m_position;


	}
}
