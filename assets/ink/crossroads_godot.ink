EXTERNAL addVectors(pos1, pos2)
EXTERNAL getPosition(uuid)

Test
-> init

=== init ===
    Test
    -> DONE
    
=== test_trainer ===
    You: Hey, Trainer.
    Trainer: Hero.
    - (top)
    + [Shop]
        >>> shop
    + [Train]
        >>> train
    + [Heal]
        >>> heal
    + [Leave]
        -> DONE
    -
    Trainer: Anythin' else?
    -> top

=== attack(entity, direction) ===
    -> slash(entity, direction)

=== slash(entity, direction) ===
    ~ temp _position = addVectors(getPosition(entity), direction)
    >>> damage {_position} 10
    // TODO: Rotation! Get rotated direction so we can offset it and attack adjacent tiles.
    // TODO: Movement! So we can rush forward multiple tiles, stop when we hit something, and damage the target.
    -
    -> DONE

=== cleave(entity, direction) ===
    ~ temp _position1 = addVectors(getPosition(entity), rotate(direction, -45))
    ~ temp _position2 = addVectors(getPosition(entity), direction)
    ~ temp _position3 = addVectors(getPosition(entity), rotate(direction, 45))
    >>> damage {_position1} 10
    >>> damage {_position2} 10
    >>> damage {_position3} 10
    // TODO: Rotation! Get rotated direction so we can offset it and attack adjacent tiles.
    // TODO: Movement! So we can rush forward multiple tiles, stop when we hit something, and damage the target.
    -
    -> DONE

=== function rotate(vec, degrees) ===
    ~ return vec

=== function addVectors(pos1, pos2) ===
    >>> pos1 + pos2
    ~ return pos1
    
=== function getPosition(_entity) ===
    ~ return "(0,0)"