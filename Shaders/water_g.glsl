#version 450 core

layout (triangles) in;
layout (triangle_strip) out;
layout (max_vertices = 3) out;

in vec3[] n;
in vec2[] t;
out vec3 n2;
out vec2 t2;

void main()
{
        int i;

        for (i = 0; i < gl_in.length(); i++)
        {
                gl_Position = gl_in[i].gl_Position;
                n2 = n[0];
                t2 = t[0];
                EmitVertex();
        }

        EndPrimitive();
}


