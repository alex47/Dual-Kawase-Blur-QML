import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    width: sourceImage.sourceSize.width
    height: sourceImage.sourceSize.height
    title: qsTr("Dual Kawase Blur")

    Item {
        // Variables
        property int iteration: 3
        property double offset: 3


        // TODO: change this to whatever image you want to blur
        Image {
            id: sourceImage
            anchors.fill: parent
            source: "lenna.png"
            visible: false
        }



        /* --- WARNING: Do not modify anything below this --- */
        id: dualKawaseBlur

        width: sourceImage.sourceSize.width
        height: sourceImage.sourceSize.height

        property int actualIteration: Math.max(0, iteration - 1)
        property int counter: 0

        property int texWidth: width / 2
        property int texHeight: height / 2

        property var blurSource: sourceImage
        property bool isDownScale: true

        function nextBlurStep() {
            if (counter <= actualIteration) {
                if (isDownScale) {
                    if (counter != actualIteration) {
                        texWidth = texWidth / 2
                        texHeight = texHeight / 2
                        blurSource = downSampleShader

                        blurTexture.scheduleUpdate()
                        counter++
                    }
                } else {
                    texWidth = texWidth * 2
                    texHeight = texHeight * 2
                    blurSource = upSampleShader

                    blurTexture.scheduleUpdate()
                    counter++
                }
            }

            if (counter == actualIteration && isDownScale) {
                isDownScale = false
                counter = 0

                downSampleShader.visible = false
                upSampleShader.visible = true

                nextBlurStep()
            }
        }

        ShaderEffectSource {
            id: blurTexture
            sourceItem: dualKawaseBlur.blurSource
            textureMirroring: ShaderEffectSource.NoMirroring
            live: false // must be false, else it goes into infinite loop
            recursive: true
            textureSize: Qt.size(dualKawaseBlur.texWidth, dualKawaseBlur.texHeight)

            onScheduledUpdateCompleted: dualKawaseBlur.nextBlurStep()
        }

        ShaderEffect {
            id: downSampleShader
            anchors.fill: sourceImage
            visible: true

            property int downSampleTexWidth: blurTexture.textureSize.width
            property int downSampleTexHeight: blurTexture.textureSize.height

            property size renderTextureSize: Qt.size(downSampleTexWidth, downSampleTexHeight)
            property size halfPixel: Qt.size(0.5 / downSampleTexWidth, 0.5 / downSampleTexHeight)
            property point offset: Qt.point(dualKawaseBlur.offset, dualKawaseBlur.offset)
            property var source: blurTexture

            fragmentShader: "
                uniform sampler2D source;
                uniform vec2 renderTextureSize;
                uniform vec2 offset;
                uniform vec2 halfPixel;

                void main()
                {
                    vec2 uv = vec2(gl_FragCoord.xy / renderTextureSize);

                    vec4 sum = texture2D(source, uv) * 4.0;
                    sum += texture2D(source, uv - halfPixel.xy * offset);
                    sum += texture2D(source, uv + halfPixel.xy * offset);
                    sum += texture2D(source, uv + vec2(halfPixel.x, -halfPixel.y) * offset);
                    sum += texture2D(source, uv - vec2(halfPixel.x, -halfPixel.y) * offset);

                    gl_FragColor = sum / 8.0;
                }"
        }

        ShaderEffect {
            id: upSampleShader
            anchors.fill: sourceImage
            visible: false

            property int upSampleTexWidth: blurTexture.textureSize.width
            property int upSampleTexHeight: blurTexture.textureSize.height

            property size renderTextureSize: Qt.size(upSampleTexWidth, upSampleTexHeight)
            property size halfPixel: Qt.size(0.5 / upSampleTexWidth, 0.5 / upSampleTexHeight)
            property point offset: Qt.point(dualKawaseBlur.offset, dualKawaseBlur.offset)
            property var source: blurTexture

            fragmentShader: "
                uniform sampler2D source;
                uniform vec2 renderTextureSize;
                uniform vec2 offset;
                uniform vec2 halfPixel;

                void main()
                {
                    vec2 uv = vec2(gl_FragCoord.xy / renderTextureSize);

                    vec4 sum = texture2D(source, uv + vec2(-halfPixel.x * 2.0, 0.0) * offset);
                    sum += texture2D(source, uv + vec2(-halfPixel.x, halfPixel.y) * offset) * 2.0;
                    sum += texture2D(source, uv + vec2(0.0, halfPixel.y * 2.0) * offset);
                    sum += texture2D(source, uv + vec2(halfPixel.x, halfPixel.y) * offset) * 2.0;
                    sum += texture2D(source, uv + vec2(halfPixel.x * 2.0, 0.0) * offset);
                    sum += texture2D(source, uv + vec2(halfPixel.x, -halfPixel.y) * offset) * 2.0;
                    sum += texture2D(source, uv + vec2(0.0, -halfPixel.y * 2.0) * offset);
                    sum += texture2D(source, uv + vec2(-halfPixel.x, -halfPixel.y) * offset) * 2.0;

                    gl_FragColor = sum / 12.0;
                }"
        }

    }
}
