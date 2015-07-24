var game = new Phaser.Game(800, 600, Phaser.AUTO, '', { preload: preload, create: create, update: update });


function preload() {
    game.load.image('sky', '/images/sky.png');
    game.load.image('ground', '/images/platform.png');
    game.load.spritesheet('dude', '/images/spritesheet.png', 32, 32);
    var platforms = game.add.group();
}

function create() {
  game.physics.startSystem(Phaser.Physics.ARCADE);
  game.add.sprite(0, 0, 'sky');


  platforms.enableBody = true;
  var ground = platforms.create(0, game.world.height - 64, 'ground');

  ground.scale.setTo(2, 2);
  ground.body.immovable = true;

  var ledge = platforms.create(400, 400, 'ground');

  ledge.body.immovable = true;
  ledge = platforms.create(-150, 250, 'ground');
  ledge.body.immovable = true;

  var player = game.add.sprite(32, game.world.height - 150, 'dude');
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
      player.body.velocity.x = -100;
      player.animations.play('left');
  }
  else if (cursors.right.isDown)
  {
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
      player.body.velocity.y = -350;
  }
}
