EXTERNAL addVectors(pos1, pos2)
EXTERNAL getPosition(entity)

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

=== slash(entity, direction) ===
    -> attack(entity, direction)

=== attack(entity, direction) ===
    ~ temp _position = addVectors(getPosition(entity), direction)
    {_position}
    -> DONE
    

=== function addVectors(pos1, pos2) ===
    ~ return pos1
    
=== function getPosition(entity) ===
    ~ return "(0,0)"