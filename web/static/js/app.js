import {Socket} from "phoenix"

class App {

  static init(){
    var id = Date.now();
    var players = {};
    var socket     = new Socket("/ws")
    socket.connect()
    socket.onClose( e => console.log("CLOSE", e))

    var chan = socket.chan("levels", {})

    chan.join('levels').receive("ignore", () => console.log("auth error"))
               .receive("ok", () => logged_player(id))
               .after(10000, () => console.log("Connection interruption"))

    chan.onError(e => console.log("something went wrong", e))
    chan.onClose(e => console.log("channel closed", e))

    chan.on("logged", user => {
      if(id != user.id){
        add_player(user.id)
      }
    })

    chan.on("moved", user => {
      if(id != user.id){
        if(players[user.id]){
          change_position(user.id, user.position)
        }
        else {
          add_player(user.id)
          change_position(user.id, user.position)
        }
      }
    })

    function logged_player(id){
      chan.push("logged", {user: id})
    }

    function add_player(id){
      var lol = game.add.sprite(32,504, 'dude');
      players[id] = lol
    }

    function change_position(id, cord){
      players[id].position =cord
    }

    var game = new Phaser.Game(800, 600, Phaser.AUTO, '', { preload: preload, create: create, update: update });
    var player  = null
    var platforms = null
    var cursors = null

    function preload() {
        game.load.image('sky', '/images/sky.png');
        game.load.image('ground', '/images/platform.png');
        game.load.spritesheet('dude', '/images/spritesheet.png', 32, 32);
    }

    function create() {
      game.physics.startSystem(Phaser.Physics.ARCADE);
      game.add.sprite(0, 0, 'sky');

      platforms = game.add.group();
      platforms.enableBody = true;
      var ground = platforms.create(0, game.world.height - 64, 'ground');

      ground.scale.setTo(2, 2);
      ground.body.immovable = true;

      var ledge = platforms.create(400, 400, 'ground');

      ledge.body.immovable = true;
      ledge = platforms.create(-150, 250, 'ground');
      ledge.body.immovable = true;

      player = game.add.sprite(32, game.world.height - 150, 'dude');
      players[id] = player
      game.physics.arcade.enable(player);

      player.body.bounce.y = 0.1;
      player.body.gravity.y = 300;
      player.body.collideWorldBounds = true;

      player.animations.add('left', [6, 4, 6, 5], 5, true);
      player.animations.add('right', [1, 2, 1, 3], 5, true);
    }

    function update() {
      game.physics.arcade.collide(player, platforms);
      cursors = game.input.keyboard.createCursorKeys();

      player.body.velocity.x = 0;

      if (cursors.left.isDown)
      {
          chan.push("moved", {'id': id, 'cord': player.position})
          player.body.velocity.x = -100;
          player.animations.play('left');
      }
      else if (cursors.right.isDown)
      {
          chan.push("moved", {'id': id, 'cord': player.position})
          player.body.velocity.x = 100;
          player.animations.play('right');
      }
      else
      {
          player.animations.stop();
          player.frame = 0;
      }
      if (cursors.up.isDown && player.body.touching.down)
      {
          chan.push("moved", {'id': id, 'cord': player.position})
          player.body.velocity.y = -350;
      }
    }
  }
}

$( () => App.init() )

export default App
