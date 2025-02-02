#include "icosahedre.h"


namespace rendersystem {

void Icosahedre::generateMesh() {

    triangles_.clear();
    vertices_.clear();

    loaders::Mesh::Vertex vert;
    glm::vec3 xyz;


    float phi=(1+sqrt(5))/2.;

    float vdata[12][3] = {
        {phi,1,0.0},
        {phi,-1,0.0},
        {-phi,1,0.0},
        {-phi,-1,0.0},

        {1,0,phi},
        {1,0,-phi},
        {-1,0,phi},
        {-1,0,-phi},

        {0,phi,1},
        {0,phi,-1},
        {0,-phi,1},
        {0,-phi,-1}
    };
    int i;
    for(i=0;i<12;i++){
        xyz[0]=vdata[i][0];
        xyz[1]=vdata[i][1];
        xyz[2]=vdata[i][2];
        vert.position_ = glm::normalize(xyz);
        vert.normal_ = glm::normalize(xyz);

        vertices_.push_back(vert);
    }

    uint tindices[20][3] ={
        {2,8,9},{9,8,0},{0,8,4},{4,8,6},{6,8,2},
        {3,11,10},{10,11,1},{1,11,5},{5,11,7},{7,11,3},
        {3,2,7},{7,2,9},{7,9,5},{5,9,0},{5,0,1},{1,0,4},{1,4,10},{10,4,6},{10,6,3},{3,6,2}

    };

    for(i=0;i<20;i++){



        triangles_.push_back( TriangleIndex(tindices[i][0], tindices[i][1], tindices[i][2]) );

    }

    nbVertices_  = vertices_. size();
    nbTriangles_ = triangles_.size();

    hasNormal_        = true;
    hasTextureCoords_ = true;

    /*
    int i;
    for(i=0;i<12;i++){
        glVertex3f vert;
        vert.position_ = glm::vec3(vdata[i][0], vdata[i][1], vdata[i][2]);
        vertices_.push_back(vert);
    }
    */


    /*
    for(i=0;i<12;i++){
        triangles_.push_back( TriangleIndex(tindices[i][0],tindices[i][1],tindices[i][2] );
    }
    */


}

}
