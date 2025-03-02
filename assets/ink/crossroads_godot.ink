EXTERNAL addVectors(pos1, pos2)
EXTERNAL getPosition(uuid)
EXTERNAL rotate(vec, deg)
EXTERNAL snapToGrid(vec)

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

=== attack(entity, direction, potency) ===
    -> slash(entity, direction, potency)

=== slash(entity, direction, potency) ===
    ~ temp _position = addVectors(getPosition(entity), direction)
    >>> damage #position={_position} #potency={potency}
    // TODO: Rotation! Get rotated direction so we can offset it and attack adjacent tiles.
    // TODO: Movement! So we can rush forward multiple tiles, stop when we hit something, and damage the target.
    -
    -> DONE

=== cleave(entity, direction, potency) ===
    ~ temp _position1 = snapToGrid(addVectors(getPosition(entity), rotate(direction, -45)))
    ~ temp _position2 = addVectors(getPosition(entity), direction)
    ~ temp _position3 = snapToGrid(addVectors(getPosition(entity), rotate(direction, 45)))
    >>> damage #position={_position1} #potency={potency}
    >>> damage #position={_position2} #potency={potency}
    >>> damage #position={_position3} #potency={potency}
    // TODO: Rotation! Get rotated direction so we can offset it and attack adjacent tiles.
    // TODO: Movement! So we can rush forward multiple tiles, stop when we hit something, and damage the target.
    -
    -> DONE

=== function snapToGrid(vec) ===
    ~ return vec
    
=== function rotate(vec, degrees) ===
    ~ return vec

=== function addVectors(pos1, pos2) ===
    >>> pos1 + pos2
    ~ return pos1
    
=== function getPosition(_entity) ===
    ~ return "(0,0)"