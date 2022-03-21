using Godot;
using System;

public class Player : KinematicBody2D
{
	private AnimatedSprite _animatedSprite;

	public override void _Ready()
	{
		_animatedSprite = GetNode<AnimatedSprite>("AnimatedSprite");
	}

	public override void _Process(float delta)
	{
		float Amount=5;
	if(Input.IsKeyPressed((int)KeyList.W)){
		this.Position += new Vector2(0,-Amount);
		_animatedSprite.Play("up");
		}
		
	if(Input.IsKeyPressed((int)KeyList.S)){
		this.Position += new Vector2(0,Amount);
		_animatedSprite.Play("down");
		}
	if(Input.IsKeyPressed((int)KeyList.A)){
		this.Position += new Vector2(-Amount,0);
		_animatedSprite.Play("left");
		}
	if(Input.IsKeyPressed((int)KeyList.D)){
		this.Position += new Vector2(Amount,0);
		_animatedSprite.Play("right");
			}
	else
		{
			_animatedSprite.Stop();
		}
	}
}
