shader_type canvas_item;
uniform sampler2D BIOME_MAP;

void fragment() {
	float cursorSize=0.005;
	float xScale=1.5f;
	// centered cursor
	if(
		((abs(0.5-cursorSize/xScale-UV.x)<0.001||abs(0.5+cursorSize/xScale-UV.x)<0.001)&&UV.y>=0.5-cursorSize&&UV.y<=0.5+cursorSize)
		||
		((abs(0.5-cursorSize-UV.y)<0.001||abs(0.5+cursorSize-UV.y)<0.001)&&UV.x>=0.5-cursorSize/xScale&&UV.x<=0.5+cursorSize/xScale)
		){
		COLOR=vec4(1,1,1,1);
	} else {
		//COLOR=vec4(0,0,0,1);
		COLOR = texture(BIOME_MAP, UV); 
	}
}
