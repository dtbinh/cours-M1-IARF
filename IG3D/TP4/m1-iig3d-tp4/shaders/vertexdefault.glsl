#version 150
/*
 * Paramètres généraux
 */
// Matrices

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 MVP;
uniform mat4 normalMatrix;

// Position des sources
uniform vec3 keyLightPosition;
uniform vec3 fillLightPosition;
uniform vec3 backLightPosition;

/*
 * Données en entrée
 */
in vec3 inPosition;
in vec3 inNormal;
in vec4 inTexCoord;

/*
 * Données en sortie
 */
// Sommet
out vec3 varNormal;
out vec4 varTexCoord;

// Eclairage
out vec3 lightDirInView[3];
out vec3 halfVecInView[3];

void computeLightingVectorsInView(in vec3 posInView, in vec3 lightPosition, out vec3 lightDir, out vec3 halfVec){


    lightDir = normalize(lightPosition - posInView);
    halfVec= (lightDir)+normalize(-posInView);
    halfVec=normalize( halfVec);

}

void main(void) {
   varNormal = vec3 ( normalMatrix *vec4(inNormal.xyz, 1.0) );
   varNormal = normalize (varNormal);

   varTexCoord = inTexCoord;

   gl_Position = MVP*vec4(inPosition.xyz, 1.0);

   vec3 inPositionCam = vec3 ( modelViewMatrix *vec4(inPosition.xyz, 1.0) );


   computeLightingVectorsInView(inPositionCam,keyLightPosition,lightDirInView[0],halfVecInView[0]);

   computeLightingVectorsInView(inPositionCam,fillLightPosition,lightDirInView[1],halfVecInView[1]);

   computeLightingVectorsInView(inPositionCam,backLightPosition,lightDirInView[2],halfVecInView[2]);




}
