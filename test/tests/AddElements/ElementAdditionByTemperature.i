[Problem]
  kernel_coverage_check = false
[]

[Mesh]
  [./gen]
    type = GeneratedMeshGenerator
    dim =  3
    xmin = 0.0
    xmax = 1.0
    ymin = 0.0
    ymax = 1.0
    zmin = 0.0
    zmax = 1.0
    nx= 10
    ny= 10
    nz= 10
  [../]
  [./left_domain]
    input = gen
    type = SubdomainBoundingBoxGenerator
    bottom_left = '0.0 0.0 0.0'
    top_right = '1.0 1.0 0.5'
    block_id = 1
  [../]
  [./right_domain]
    input = left_domain
    type = SubdomainBoundingBoxGenerator
    bottom_left = '0.0 0.0 0.5'
    top_right = '1.0 1.0 1.0'
    block_id = 2
  [../]
  [./sidesets]
    input = right_domain
    type = SideSetsAroundSubdomainGenerator
    normal = '0 0 1'
    block = 1
    new_boundary = 'moving_interface'
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
  block = '1 2'
[]

[Variables]
  [./disp_x]
    order = FIRST
    family = LAGRANGE
    # Use the initial Condition block underneath the variable
    # for which we want to apply this initial condition
    [./InitialCondition]
      type = ConstantIC
      value = 0.0
    [../]
  [../]

  [./disp_y]
    order = FIRST
    family = LAGRANGE
  [../]

  [./disp_z]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[AuxVariables]
  [./temperature]
    order = CONSTANT
    family = MONOMIAL
  [../]
  
  [./stress_xx]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[ICs]
  [./temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_load_init
  [../]
[]

[Functions]
  [./temperature_load]
    type = ParsedFunction
    value = '303.0+((200.0-t)*z)'
  [../]
  [./temperature_load_init]
    type = ParsedFunction
    value = '303.0+(200.0*z)'
  [../]
  [./disp_load]
    type = ParsedFunction
    value = '-min(0.001*t,0.001)'	
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y disp_z'
    use_displaced_mesh = true
    add_variables = true
	block = '1 2'
  [../]
[]

[AuxKernels]
  [./tempfuncaux]
    type = FunctionAux
    variable = temperature
    function = temperature_load
  [../]
  
  [./stress_xx]
    type = RankTwoAux
    variable = stress_xx
    rank_two_tensor = stress
    index_j = 0
    index_i = 0
    execute_on = timestep_end
  [../]
[]

[Materials]
  [./stress]
    type = ComputeFiniteStrainElasticStress
  [../]
  [./elasticity_tensor]
    type = ComputeElasticityTensor
    fill_method = symmetric9
    C_ijkl = '1.5e6 0.75e6 0.75e6 1.5e6 0.75e6 1.5e6 0.375e6 0.375e6 0.375e6'
  [../]
  [./strain]
    type = ComputeFiniteStrain
    displacements = 'disp_x disp_y disp_z'
  [../]
[]

[BCs]
  [./z0]
    type = DirichletBC
    variable = disp_z
    boundary = front
    value = 0.0
  [../]

  [./y0]
    type = DirichletBC
    variable = disp_y
    boundary = bottom
    value = 0.0
  [../]

  [./x0]
    type = DirichletBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]
  
  [./z1]
    type = FunctionDirichletBC
    variable = disp_z
    boundary = back
    function = disp_load
  [../]
[]

[Preconditioning]
  [./smp]
    type = SMP
    full = true
  [../]
[]


[Executioner]

  type = Transient
  solve_type = 'PJFNK'
  petsc_options = '-snes_ksp_ew'
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre    boomeramg          31'
  line_search = 'none'
  l_max_its = 50
  nl_max_its = 20
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-6
  l_tol = 1e-8

  #automatic_scaling = true

  #solve_type = 'NEWTON'

  #petsc_options_iname = '-pc_type'
  #petsc_options_value = 'lu'

  #line_search = 'none'

  #l_max_its = 10
  #nl_max_its = 20
  #nl_rel_tol = 1e-4

  start_time = 0.0
  end_time = 50.0
  dt = 1.0
  dtmin = 1e-4
[]

[UserObjects]
  [./activated_elem_uo]
    type = ActivateElementsCoupled
    execute_on = timestep_begin
    coupled_var = temperature
    activate_value = 403.0
	activate_type = below
    active_subdomain_id = 1
	inactive_subdomain_id = 2
    expand_boundary_name = 'moving_interface'
  [../]
[]

[Outputs]
  exodus = true
  interval = 10
[]

