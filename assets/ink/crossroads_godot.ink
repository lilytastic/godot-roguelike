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
    come on
    ~ temp _position = addVectors(getPosition(entity), direction)
    // >>> {_position} ???
    wtf
    -
    -> DONE
    

=== function addVectors(pos1, pos2) ===
    >>> pos1 + pos2
    ~ return pos1
    
=== function getPosition(_entity) ===
    ~ return "(0,0)"