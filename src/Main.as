package
{
	import com.amorphous.flame.Fire;
	import com.amorphous.flame.fields.Fields;
	import com.amorphous.flame.fields.WindPoint;
	import com.amorphous.flame.particles.display.FireCreator;
	import com.amorphous.flame.particles.display.ParticleDisplay;
	import com.amorphous.flame.particles.objects.Particle;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuBuiltInItems;
	import flash.ui.ContextMenuItem;
	import flash.utils.getTimer;
	
	import ru.inspirit.utils.ColorUtils;
	import ru.inspirit.utils.FluidSolver;
	
	import test.Screenshot;
	
	/**
	 * Sample class to run a flame (not a part of the fire package)
	 * @author Diana Liao
	 */
	public class Main extends Sprite
	{
		//Create a new fire object
		public var fire:Fire = new Fire(0, 0, 320, 240, 45,45, 0);
		public var frame:int = 0;
		public function Main()
		{
			stage.frameRate = 60;
			stage.addChild(fire);
			
			//Fire parameters must be set AFTER the flame is added to the stage.
			
			//how many particles can be onscreen at once?
			fire.maxParticles = 4000;
			
			//the shape of the particle (0 - rectangular; 1 - round; 2 - lines)
			fire.particleType = 0;
			
			//how large each particle is (in pixels)
			fire.particleSize = 4;
			
			//the rate at which the fire burns (the higher this number, the bigger and wilder the flame
			fire.exothermicness = 0;
			
			//whether to draw the grey smoke in the background
			fire.drawSmoke = true;
			
			initStage();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseDown);
		}
		private function initStage():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			
		}
		private function mouseDown(e:MouseEvent):void
		{
			
			//continually replenishes fuel based on mouse position
			if (e.buttonDown == true)
			{
			//	stage.frameRate = 60;
			fire.burnFuelCircle(stage.mouseX-fire.x,stage.mouseY-fire.y,3);
			}
		}
		private function pause():void
		{
			stage.frameRate = 0;
		}
	}
}