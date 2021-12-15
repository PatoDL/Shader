using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Explorer : MonoBehaviour
{
    public Material mat = null;
    public Vector2 pos;
    public float scale;

    private Vector2 smoothPos;
    private float smoothScale;

    private void UpdateShader()
    {
        smoothPos = Vector2.Lerp(smoothPos, pos, .03f);
        smoothScale = Mathf.Lerp(smoothScale, scale, .03f);

        float aspect = (float)Screen.width / (float)Screen.height;

        float scaleX = smoothScale;
        float scaleY = smoothScale;

        if (aspect > 1f)
        {
            scaleY /= aspect;
        }
        else
        {
            scaleX *= aspect;
        }

        mat.SetVector("_Area", new Vector4(smoothPos.x, smoothPos.y, scaleX, scaleY));
    }

    private void HandleInputs()
    {
        if(Input.GetKey(KeyCode.KeypadPlus))
        {
            scale *= .99f;
        }

        if (Input.GetKey(KeyCode.KeypadMinus))
        {
            scale *= 1.01f;
        }

        if (Input.GetKey(KeyCode.A))
        {
            pos.x -= .01f*scale;
        }
        if (Input.GetKey(KeyCode.D))
        {
            pos.x += .01f * scale;
        }

        if (Input.GetKey(KeyCode.S))
        {
            pos.y -= .01f * scale;
        }
        if (Input.GetKey(KeyCode.W))
        {
            pos.y += .01f * scale;
        }
    }

    void FixedUpdate()
    {
        HandleInputs();
        UpdateShader();
    }


}
