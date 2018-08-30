#version 450 core

layout (points) in;
layout (points) out;
layout (max_vertices = 4) out;

in vec4[] sv;
out vec4 v;

uniform mat4 View;
uniform mat4 Projection;

void main()
{
        vec4 inv = sv[0];
        vec4 ViewVec = View * inv;                      // transform to view space
        gl_Position = Projection * ViewVec;             // project onto screen
        v = gl_Position;
        EmitVertex();
        EndPrimitive();

        inv.x = inv.x * -1;
        ViewVec = View * inv;                           // transform to view space
        gl_Position = Projection * ViewVec;             // project onto screen
        v = gl_Position;
        EmitVertex();
        EndPrimitive();

        inv.z = inv.z * -1;
        ViewVec = View * inv;                           // transform to view space
        gl_Position = Projection * ViewVec;             // project onto screen
        v = gl_Position;
        EmitVertex();
        EndPrimitive();

        inv.x = inv.x * -1;
        ViewVec = View * inv;                           // transform to view space
        gl_Position = Projection * ViewVec;             // project onto screen
        v = gl_Position;
        EmitVertex();
        EndPrimitive();
}


