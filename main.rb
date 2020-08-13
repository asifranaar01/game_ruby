require 'rubygems'
require 'gosu'
require "json"

# This function imports the JASON file and stores it into a hash table
def read_jason(file_path)
    json_file = File.read(file_path)
    data_hash = JSON.parse(json_file)
    return data_hash
end 

# This function is used to generate all the images used in the game
class ArtWork
	attr_accessor :bmp

	def initialize (file)
		@bmp = Gosu::Image.new(file)
	end
end

# This function is used to generate all the sound effects used in the game
class Sound
	attr_accessor :bmp

	def initialize (file)
		@bmp = Gosu::Song.new(file)
	end
end

# Reading the JASON file to load the Game presets
GAME_PRESET = read_jason("preset.json")
# Defining the screen dimensions
SCREEN_HEIGHT = GAME_PRESET["SCREEN_HEIGHT"]
SCREEN_WIDTH = GAME_PRESET["SCREEN_WIDTH"]
COUNTER = GAME_PRESET["COUNTER"]

# Enumerator for the Game play
module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

# Defing the player class controled by the user
class Player
  attr_reader :x, :y, :score, :radius, :life

  def initialize()
     @image_player = ArtWork.new("images/player.PNG")
     @vel_x = @vel_y = GAME_PRESET["player_vel"]
     @x = (SCREEN_WIDTH * 0.5) - 20
     @y = SCREEN_HEIGHT * 0.75
     @score = 0
     @radius = 40
     @life = 3
  end
  
  # This procedure increments the score of the player
  def update_score()
     @score += GAME_PRESET["score_increment"]
  end

  # Procedure to reduce the life of the player 
  def lose_life()
     @life -= 1
  end

  # Move the Space Ship to the left
  def move_left 
   if @x - @vel_x > GAME_PRESET["player_move_left"]
     @x -= @vel_x
   end
  end

  # Move the Space Ship to the right
  def move_right
    if @x + @vel_x < SCREEN_WIDTH - GAME_PRESET["player_move_right"]
      @x += @vel_x
    end
  end

  # Move the Space Ship forward
  def move_up
    if @y + @vel_y > GAME_PRESET["player_move_up"]
      @y -= @vel_y
    end
  end

  # Move the Space Ship backwards
  def move_down
    if @y + @vel_y < SCREEN_HEIGHT - GAME_PRESET["player_move_down"]
      @y += @vel_y
    end
  end

  # Draw procedure for the Player calss
  def draw
     @image_player.bmp.draw(@x, @y, ZOrder::TOP)
  end
end

# Class for the Bullets used in the game
class Bullet
  attr_reader :x, :y, :type, :radius

  def initialize(x,y, type)
     @x = x
     @y = y
     @SPEED = GAME_PRESET["bullet_speed"]
     @type = type
     @radius = 4
    # If the bullet has been fired by the player
    if @type == 'good'
      @image = ArtWork.new("images/bullet_orange.png")
    # If the bullet has been fired by the alien
    elsif @type == 'evil'
      @image = ArtWork.new("images/bullet_green.png")
    end
  end

  # Moving thr bullet across the screen after being fired
  def move
    # Move bullet fired by the Spaceship up the screen 
    if @type == 'good'
      @y -=  @SPEED
    # Move bullet fired by the Aliens down the screen 
    elsif @type == 'evil'
      @y +=  @SPEED
    end
  end

  # Draw function for the bullet class
  def draw
     @image.bmp.draw(@x - @radius, @y- @radius, 1)
  end
end

# Defining the Alien class (Opponent in the game)
class Alien
  attr_reader :x, :y, :row_pos, :height_limit, :radius

  def initialize(row_pos, start_pos, height_limit)
     @image = ArtWork.new("images/alien1.png")
     @start_pos = start_pos
     @x = row_pos * 40 + @start_pos
     @y = 30
     @x_direction = GAME_PRESET["alien_x"]
     @y_direction = GAME_PRESET["alien_y"]
     @radius = 25
     @height_limit = height_limit
  end

  # Procedure to move the Alien 
  def move
     @x += @x_direction
     @y += @y_direction
    # Preventing the Alien moving out of the screen
    if @x > (SCREEN_WIDTH - GAME_PRESET["alien_reach"]) || @x < 0
      @x_direction= -@x_direction
    elsif @y > (SCREEN_HEIGHT * @height_limit)
       @y_direction = 0
    end
  end

  # Draw Aliens on the screen
  def draw
      @image.bmp.draw(@x, @y, ZOrder::TOP)
  end
end

# This is the driver class of the Game
class SpaceWarGame < (Example rescue Gosu::Window)
  def initialize
    # replace hard coded values with global constants:
     super SCREEN_WIDTH, SCREEN_HEIGHT
     self.caption = "Space War Game"
     @background_image = ArtWork.new("images/space.jpg")
     @bullet_sound =  Sound.new("sounds/bullet.flac")
     @alien_sound =  Sound.new("sounds/alien.flac")
     @ship_hit_sound = Sound.new("sounds/ship_hit.ogg")
     @explosion_sound =  Sound.new("sounds/explosion.flac")
     @player = Player.new()
     @aliens = Array.new
     @bullets = Array.new
     @life_line = [@heart,@heart, @heart]
     @explosion = ArtWork.new("images/explosion.png")
     @heart = ArtWork.new("images/life.png")
     @blank_heart = ArtWork.new("images/blank_life.png")
     @font = Gosu::Font.new(20)
     @seconds_elapsed = 1
     @fleet = 1
     @explode = false
     @explode_x, @explode_y = 0
     @count, @game_play_time = 0
     @heart_list = [@heart, @heart, @heart]
     @level = GAME_PRESET["level_initial"]
     @height = GAME_PRESET["initial_height"]
     @alien_count = GAME_PRESET["count_alien"]
     @fleet_limit = GAME_PRESET["fleet_limit"]
     @random = GAME_PRESET["rand_generate"]
     @alien_fire_rand = GAME_PRESET["rand_fire"]
     generate_aliens(GAME_PRESET["initial_position_fleet"], @height)
  end

  # This procedure increases the difficulty level of the game 
  def level_up()
     # Incrementing the level
     @level += 1
     # Incrasing the number of aliens in each fleet 
     if @alien_count <6
         @alien_count += 1
     end 
     # Reducing the random number to that the events are more likely to occur 
     @random -= 100
     @alien_fire_rand -= 100
     # Increasing the maximum number of Alien fleets 
     @fleet_limit += 1
    end 

  # Returns the score of the Game
  def get_score()
     return @player.score()
  end

  # Returns the time of the Gameplay
  def get_game_play_time()
     return @game_play_time 
  end 

  def update
    # Time of Gameplay
    @game_play_time = Gosu.milliseconds/1000
    # Actions basesd on keyboard inputs
    if Gosu.button_down? Gosu::KB_LEFT
      @player.move_left
    end
    if Gosu.button_down? Gosu::KB_RIGHT
      @player.move_right
    end
    if Gosu.button_down? Gosu::KB_UP
      @player.move_up
    end
    if Gosu.button_down? Gosu::KB_DOWN
      @player.move_down
    end
    if Gosu.button_down? Gosu::KB_SPACE 
      # Fire bullets when Space bar is pressed
      player_fire_bullet()
    end    
    
    # The level is increased only after a certain period of game play 
    # Maximum level is - 10
    if Gosu.milliseconds > @level * GAME_PRESET["level_counter"] and @level < 10
        level_up()
    end 
    # Checks if the bullets has hit the Player or the Aliens
    check_collision()
    # This procedure adds aliens to the game 
    add_alien_fleet()
    alien_fire_bullet()
    # Moving all the Aleins in the game
    @aliens.each { |alien| alien.move }
    # Moving all the bullets fired in the game
    @bullets.each { |bullet| bullet.move}
    # Removing the bullets which are not not within the screen
    remove_unused_bullets()
  end

  # Removing the bullets which have moved pass the screen 
  def remove_unused_bullets()
    # All the bullet objects are looped through
    @bullets.dup.each { |bullet|
    # Determines if a bullet is outside the screen
    bullet.x > SCREEN_HEIGHT || bullet.x < 0
    }
  end 

  # Procedure for the aliens to fire bullets 
  def alien_fire_bullet()
     # The aliens will fire bullets at random, 
     # The randomness is controlled by @alien_fire_rand
      @aliens.each { |alien|
        if rand(@alien_fire_rand) == 0
            @bullets.push Bullet.new(alien.x, alien.y+ 40, 'evil')
        end
      }
    end

    # Procedure allows the player to fire bullets
  def player_fire_bullet()
    # This makes sure that bullets are fired after certain intervals
    if Gosu.milliseconds > (@seconds_elapsed * COUNTER)
      @seconds_elapsed = Gosu.milliseconds
      @bullet_sound.bmp.play()
      # Generating a bullet object
      @bullets.push Bullet.new((@player.x+ 33), @player.y, 'good')
    end 
  end

  # Introcusing a new fleet of aliens in the game
  def add_alien_fleet()
    # Only generate new fleet of aliens if the current count of fleets is less than @fleet_limit
    if rand(@random) == 0 and @fleet < @fleet_limit
      @fleet +=1
      position = rand(SCREEN_WIDTH/2)
      @height -= GAME_PRESET["space_fleet"]
      # Calling the procedure to generate aliens
      generate_aliens(position, @height)
    end
    # If the aliens reach the top level of the screen bring then down
    if @height < 0.3
      @height = GAME_PRESET["initial_height"]
    end 
  end 

  # Procedure to generate aliens 
  def generate_aliens(position, height)
    # Looping until the number of Aliens in a fleet is reached
    for i in 0...@alien_count
      @aliens.push(Alien.new(i, position, height))
      @alien_sound.bmp.play
    end
  end

  # Procedure to handle collision between Alien and the bullet
  def alien_hit(alien, bullet)
    # Deleting the alien and the bullet object
    @aliens.delete alien
    @bullets.delete bullet
    @explode = true
    @player.update_score()
    # Setting the coordinates for the explosion
    @explode_x = alien.x
    @explode_y = alien.y
    @explosion_sound.bmp.play 
  end 

  # Procedure to handle collision between Player and the bullet
 def player_hit(bullet)
     @bullets.delete bullet
     @ship_hit_sound.bmp.play
     # If the player has lost all the lifeline end the game
     if @player.life == 0
        # Ending the game
        GameOverWindow.new.show
        close
     end 
     # Player lost one  lifeline
     @player.lose_life()
     # Plaing a blank heart to represent it
     @heart_list[@player.life] = @blank_heart
     @heart = @blank_heart 
 end 

  # Precdure which takes care of the collions in the game
  def check_collision()
     # Looping through all the aliens in the game
      @aliens.each { |alien|
      # Looping through all the bulletss in the game
      @bullets.each { |bullet|
      # Distance between the bullet and the alien
      distance = Gosu.distance(alien.x, alien.y, bullet.x, bullet.y)
      # Distance between the bullet and the player
      hit_distance = Gosu.distance(@player.x, @player.y, bullet.x, bullet.y)
      # Bullets fired by the Player fit the Alien
      if distance < alien.radius + bullet.radius and bullet.type == 'good'
        alien_hit(alien, bullet)
      # Bullets fired by the Alien hit the Player
      elsif hit_distance < @player.radius + bullet.radius and bullet.type == 'evil'
         player_hit(bullet)
      end
      }
    }
    end

 
  # procedure to create sound effects in the game
  def play_track(path)
     @song = Gosu::Song.new(path)
     @song.play(false)
  end

  def draw
     @background_image.bmp.draw(0, 0, ZOrder::BACKGROUND)
     @player.draw
     # Drawing all the bullets generated in the game
     @bullets.each { |bullet| bullet.draw }
     # Drawing all the aliens in the game
     @aliens.each { |alien| alien.draw }
     # Placing the lifelines as hearts 
     draw_heart(@heart_list)
     # Visual if an explosion occurs 
    if @explode == true
      explode()
    end
     # Placing the Score and Level information in the screen 
     @font.draw_text("Score : #{@player.score}", 10, 10, ZOrder::TOP , 1.0, 1.0, Gosu::Color::YELLOW)
     @font.draw_text("Level : #{@level}", 10, 30, ZOrder::TOP , 1.0, 1.0, Gosu::Color::RED)
  end

  # Procedure to represent the lifeline of the player 
  def draw_heart(heart_list)
    for i in 1..heart_list.length()
      heart_list[i-1].bmp.draw( SCREEN_WIDTH - (i*30), 10, ZOrder::TOP )
    end
  end

  # Procedure to add the visuals of explosion
  def explode()
     # drawing explosion scene
     @explosion.bmp.draw(@explode_x, @explode_y, ZOrder::TOP)
     # Playing the sound of an explosion
     @explosion_sound.bmp.play
     @count += 1
     # Showing the visual for 20 update() counts
    if @count == 20
      @explode = false
      @count = 0
    end
  end

  # If Esc button is pressed close the game
  def button_down(id)
    if id == Gosu::KB_ESCAPE
      close
    else
      super
    end
  end
end

# Class for the user interface shown at the start and at the end of the game
class UI_functions
    attr_reader :pos, :button_font, :font , :big_font, :pos
  
    def initialize()
       @button_font = Gosu::Font.new(20)
       @font = Gosu::Font.new(20)
       @big_font= Gosu::Font.new(40)
       @pos = (SCREEN_WIDTH/2)
    end

    # Procedure to place button on the screen
    def place_button(x, y, message)
        Gosu.draw_rect(x, y, 70, 45, Gosu::Color::GREEN, ZOrder::MIDDLE, mode=:default)
        @button_font.draw_text(message, x+5, y+10, ZOrder::TOP, 1.0, 1.0, Gosu::Color::BLACK)
    end
    
    # Checks if the user hovers over the button
    def mouse_over_button(mouse_x, mouse_y)
        if ((mouse_x >= (SCREEN_WIDTH/3) + 100 and mouse_x <= (SCREEN_WIDTH/3) + 160) and (mouse_y >= 300 and mouse_y <= 345)) 
          return true
        else
          return false
        end
    end
  
end

class WelcomeWindow < (Example rescue Gosu::Window)

  def initialize
     super(SCREEN_WIDTH, SCREEN_HEIGHT, false)
     @background_image = ArtWork.new("images/apod.jpg")
     @function_UI = UI_functions.new()
     @sound = Sound.new("sounds/space.ogg")
     @sound.bmp.play
    end

    # Providing all the instruction to the user before starting the game
  def draw
     @background_image.bmp.draw(0, 0, ZOrder::BACKGROUND)
     @function_UI.place_button((SCREEN_WIDTH/3) + 100, 300, "Start!")
     @function_UI.big_font.draw_text("SPACE WAR", @function_UI.pos- 120, 30, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     @function_UI.big_font.draw_text("Instructions: ", @function_UI.pos-100, 100, ZOrder::TOP, 1.0, 1.0, Gosu::Color::RED)
     @function_UI.font.draw_text("# Press SPACE BAR to fire bullets", @function_UI.pos-180, 140, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     @function_UI.font.draw_text("# Use the ARROW KEYS to navigate the Spaceship", @function_UI.pos-180, 180, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     @function_UI.font.draw_text("# You have 3 Life Lines", @function_UI.pos-180, 220, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     @function_UI.font.draw_text("# Press ESC to leave the Game", @function_UI.pos-180, 260, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     draw_border((SCREEN_WIDTH/3) + 105, 305)
  end 

    # When a user hovers over a button draw a border
  def draw_border(x1, y)
     if @function_UI.mouse_over_button(mouse_x, mouse_y)
         draw_line(x1, y, Gosu::Color::BLUE, x1+60, y, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
         draw_line(x1, y+35, Gosu::Color::BLUE, x1+60, y+35, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
         draw_line(x1, y,Gosu::Color::BLUE, x1, y+35, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
         draw_line(x1+60, y,Gosu::Color::BLUE, x1+60, y+35, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
     end 
    end

  def needs_cursor?; true; end

  def button_down(id)
     case id
     when Gosu::MsLeft
         # Start the Game when user presses the button
         if @function_UI.mouse_over_button(mouse_x, mouse_y)
            @sound.bmp.stop
            close
            # Starting the game
            GAME.show if __FILE__ == $0
         end 
     end
    end
end

class GameOverWindow < (Example rescue Gosu::Window)

  def initialize
     super(SCREEN_WIDTH, SCREEN_HEIGHT, GAME, false)
     @background_image = ArtWork.new("images/apod.jpg")
     @score = GAME.get_score()
     @game_play_time = GAME.get_game_play_time()
     @score_font = Gosu::Font.new(30)
     @function_UI = UI_functions.new()
     @sound =  Sound.new("sounds/background.ogg")
     @sound.bmp.play
  end 

  # Showing the information after the game has ended
  def draw
     @background_image.bmp.draw(0, 0, ZOrder::BACKGROUND)
     @function_UI.place_button((SCREEN_WIDTH/3) + 100, 300, "Close")
     draw_border((SCREEN_WIDTH/3) + 105, 305, mouse_x, mouse_y)
     @function_UI.big_font.draw_text("GAME OVER!", @function_UI.pos- 120, 30, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     @score_font.draw_text("Your Score: #{@score}", @function_UI.pos-100, 200, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
     @score_font.draw_text("Time of Game PLay: #{@game_play_time} Seconds", @function_UI.pos-140, 100, ZOrder::TOP, 1.0, 1.0, Gosu::Color::YELLOW)
  end 
 
  # When a user hovers over a button draw a border
  def draw_border(x1, y, mouse_x, mouse_y)
    if @function_UI.mouse_over_button(mouse_x, mouse_y)
      draw_line(x1, y, Gosu::Color::BLUE, x1+60, y, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
      draw_line(x1, y+35, Gosu::Color::BLUE, x1+60, y+35, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
      draw_line(x1, y,Gosu::Color::BLUE, x1, y+35, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
      draw_line(x1+60, y,Gosu::Color::BLUE, x1+60, y+35, Gosu::Color::BLUE, ZOrder::TOP, mode=:default)
    end   
  end 

  def needs_cursor?; true; end

  def button_down(id)
    case id
    when Gosu::MsLeft
      # Closing the game when the user clicks the button
      if @function_UI.mouse_over_button(mouse_x, mouse_y)
        close
      end 
    end 
  end
end

# Starting the Game

GAME = SpaceWarGame.new
WelcomeWindow.new.show
