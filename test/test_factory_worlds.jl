let
    for shape in [(1,1),(2,1),(1,2),(2,2),(3,2)]
        for idx in 1:config_tuple_to_index(shape,shape)
            tup = config_index_to_tuple(shape,idx)
            config_idx = config_tuple_to_index(shape,tup)
            # @show shape, tup, idx, config_idx
            @test idx == config_idx
        end
        idx = 0
        for i in 1:shape[1]
            for j in 1:shape[2]
                idx += 1
                @test (i,j) == config_index_to_tuple(shape,idx)
            end
        end
    end
end
let
    dims = (2,2)
    # initialize a dense grid graph
    G = initialize_grid_graph_from_vtx_grid(initialize_dense_vtx_grid(dims...))
    # construct the corresponding vertex coordinate list
    vtxs = [(i,j) for i in 1:dims[1] for j in 1:dims[2]]
    vtx_map = construct_vtx_map(vtxs,dims)
    edge_cache = construct_edge_cache(vtxs,vtx_map)
    @test validate_edge_cache(G,vtxs,edge_cache)
end
let
    grid = initialize_regular_vtx_grid(;n_obstacles_x=1,n_obstacles_y=1)
    dims = size(grid)
    base_vtxs = vtx_list_from_vtx_grid(grid)
    # 1   2   3   4   5   6
    # 7   8   9  10  11  12
    # 13  14   0   0  15  16
    # 17  18   0   0  19  20
    # 21  22  23  24  25  26
    # 27  28  29  30  31  32
    indicator_grid = IndicatorGrid(grid)
    s = (2,2)
    filtered_grid = convolve_with_occupancy_kernel(indicator_grid,s)
    vtx_map = VtxGrid(filtered_grid[1:end-s[1]+1,1:end-s[2]+1])
    vtx_list = vtx_list_from_vtx_grid(vtx_map)
    graph = initialize_grid_graph_from_vtx_grid(vtx_map)
    # mtx = spzeros(Int,nv(graph),nv(graph))
    # sm = SparseDistanceMatrix(graph,mtx)
    sm = SparseDistanceMatrix(graph)
    @test sm(1,2) == 1
    @test sm(4,2) == 2

    m = RemappedDistanceMatrix(sm,grid,base_vtxs,vtx_map,vtx_list,s)
    @test m(1,2,(1,1)) == 1
    @test m(4,2,(1,1)) == m(4,2) == 2
end
let
    grid = initialize_regular_vtx_grid()
    dims = size(grid)
    vtxs = [(i,j) for i in 1:dims[1] for j in 1:dims[2] if grid[i,j] > 0]
    sort!(vtxs, by=vtx->grid[vtx...])
    zones = [v for (v,vtx) in enumerate(vtxs) if sum(grid[clip(vtx[1]-1,1,dims[1]):clip(vtx[1]+1,1,dims[1]),clip(vtx[2]-1,1,dims[2]):clip(vtx[2]+1,1,dims[2])] .> 0) == 7]
    vtx_map = construct_vtx_map(vtxs,dims)
    expanded_zones = construct_expanded_zones(vtxs,vtx_map,zones)
    @test GraphUtils.validate_expanded_zones(vtx_map,expanded_zones)
end
let
    grid = initialize_regular_vtx_grid(;n_obstacles_x=1,n_obstacles_y=1)
    dims = size(grid)
    vtxs = [(i,j) for i in 1:dims[1] for j in 1:dims[2] if grid[i,j] > 0]
    # 1   2   3   4   5   6
    # 7   8   9  10  11  12
    # 13  14   0   0  15  16
    # 17  18   0   0  19  20
    # 21  22  23  24  25  26
    # 27  28  29  30  31  32
    dist_mtx_map = DistMatrixMap(grid,vtxs)
    dist_matrix = get_dist_matrix(initialize_grid_graph_from_vtx_grid(grid))
    v1 = 13
    v2 = 15
    @test get_distance(dist_mtx_map,v1,v2,(1,1)) == dist_matrix[v1,v2]
    @test get_distance(dist_mtx_map,v1,v2,(1,2)) == dist_matrix[v1,v2]
    @test get_distance(dist_mtx_map,v1,v2,(2,1)) == dist_matrix[v1,v2] + 2
    @test get_distance(dist_mtx_map,v1,v2,(2,2)) == dist_matrix[v1,v2] + 2
    v3 = 18
    v4 = 20
    config = 4
    @test get_distance(dist_mtx_map,v3,v4,(2,2),config) == dist_matrix[v1,v2] + 2
end
let
    env = construct_regular_factory_world()
    get_x_dim(env)
    get_y_dim(env)
    get_cell_width(env)
    get_transition_time(env)
    get_vtxs(env)
    get_pickup_zones(env)
    get_dropoff_zones(env)
    get_obstacles(env)
    get_pickup_vtxs(env)
    get_dropoff_vtxs(env)
    get_obstacle_vtxs(env)
    GridFactoryEnvironment(env,env.graph)
    Base.zero(env)
    LightGraphs.edges(env)
    LightGraphs.edgetype(env)
    LightGraphs.has_edge(env,1,2)
    LightGraphs.has_vertex(env,1)
    LightGraphs.inneighbors(env,1)
    LightGraphs.is_directed(env)
    LightGraphs.ne(env)
    LightGraphs.nv(env)
    LightGraphs.outneighbors(env,1)
    LightGraphs.vertices(env)
    get_num_free_vtxs(env)
    get_free_zones(env)

    @test validate_expanded_zones(env.vtx_map,env.expanded_zones)

    filename = "env.toml"
    open(filename,"w") do io
        TOML.print(io, TOML.parse(env))
    end
    env2 = read_env(filename)

    @test get_vtxs(env) == get_vtxs(env2)
    @test nv(env.graph) == nv(env2.graph)
    @test ne(env.graph) == ne(env2.graph)

    construct_factory_env_from_vtx_grid(env.vtx_map)
    # construct_random_factory_world()
    # sample_random_robot_locations(env,10)
end
let
    xdim = 4
    ydim = 4
    vtx_grid = initialize_dense_vtx_grid(xdim,ydim)
    env_graph = initialize_grid_graph_from_vtx_grid(vtx_grid)
    vtxs = [(i,j) for i in 1:xdim for j in 1:ydim]
    factory_env = GridFactoryEnvironment(
        graph = env_graph,
        x_dim=xdim,
        y_dim=ydim,
        vtxs=vtxs
    )
end
# test custom envs for different-sized robot sizes
let
    vtx_grid = initialize_dense_vtx_grid(4,4)
    #  1   2   3   4
    #  5   6   7   8
    #  9  10  11  12
    # 13  14  15  16
    env = construct_factory_env_from_vtx_grid(vtx_grid)
    for i in 1:3
        for j in 1:3
            # @show env.expanded_zones[vtx_grid[i,j]]
        end
    end
end
let
    factory_env = construct_regular_factory_world(;n_obstacles_x=1,n_obstacles_y=1)
    # 1   2   3   4   5   6
    # 7   8   9  10  11  12
    # 13  14   0   0  15  16
    # 17  18   0   0  19  20
    # 21  22  23  24  25  26
    # 27  28  29  30  31  32
    dist_matrix = get_dist_matrix(factory_env)
    dist_mtx_map = factory_env.dist_function

    v1 = 13
    v2 = 15
    @test get_distance(dist_mtx_map,v1,v2) == dist_matrix[v1,v2]
    @test get_distance(dist_mtx_map,v1,v2,(1,1)) == dist_matrix[v1,v2]
    @test get_distance(dist_mtx_map,v1,v2,(1,2)) == dist_matrix[v1,v2]
    @test get_distance(dist_mtx_map,v1,v2,(2,1)) == dist_matrix[v1,v2] + 2
    @test get_distance(dist_mtx_map,v1,v2,(2,2)) == dist_matrix[v1,v2] + 2

    v3 = 18
    v4 = 20
    config = 4
    @test get_distance(dist_mtx_map,v3,v4,(2,2),config) == dist_matrix[v1,v2] + 2
end
