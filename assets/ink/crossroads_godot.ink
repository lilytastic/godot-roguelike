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



// Scripted skills //

// TODO: Movement! So we can rush forward multiple tiles, stop when we hit something, and damage the target.
    
=== attack(entity, direction, potency) ===
    ~ temp _position = addVectors(getPosition(entity), direction)
    >>> damage #position={_position} #potency={potency} #direction={direction}
    -
    -> DONE

=== slash(entity, direction, potency) ===
    ~ temp _position = addVectors(getPosition(entity), direction)
    >>> damage #position={_position} #potency={potency} #direction={direction}
    -
    -> DONE

=== cleave(entity, direction, potency) ===
    ~ temp _position1 = snapToGrid(addVectors(getPosition(entity), rotate(direction, 45)))
    ~ temp _position2 = snapToGrid(addVectors(getPosition(entity), direction))
    ~ temp _position3 = snapToGrid(addVectors(getPosition(entity), rotate(direction, -45)))
    >>> damage #position={_position1} #potency={potency} #direction={direction}
    >>> damage #position={_position2} #potency={potency} #direction={direction}
    >>> damage #position={_position3} #potency={potency} #direction={direction}
    -
    -> DONE

=== rush(entity, direction, potency) ===
    ~ temp _position = addVectors(getPosition(entity), direction)
    >>> move #entity={entity} #direction={direction}
    >>> move #entity={entity} #direction={direction}
    >>> move #entity={entity} #direction={direction}
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