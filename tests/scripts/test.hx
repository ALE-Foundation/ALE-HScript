function oso():Dynamic
    return {x: 10, y: () -> 'donde'};

trace(oso().y());