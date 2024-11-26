# Approximate Dr. Sinter Geometry
# Configuration: Two stainless steel electrodes (with cooling channels) with two
#                large spacers, and one die-and-plungers assembly.
#                RZ, axisymmetric.
# BCs:
#    Potential:
#       V (top electrode, top surface) --> Neumann condition specifiying potential
#                                          based on applied RMS Current (980 A)
#                                          and cross-sectional electrode area (see
#                                          elec_top BC below). Current turned off
#                                          at 1200 s.
#       V (bottom electrode, bottom surface) = 0 V
#       V (elsewhere) --> natural boundary conditions (no current external to circuit)
#    Temperature:
#       T (top electrode, top surface) = 293 K
#       T (bottom electrode, bottom surface) = 293 K
#       T (vertical right side) --> simple radiative BC into black body at 293 K
#       T (horizonal surfaces) --> GapHeatTransfer
#       T (water channel) --> simple convective BC into "water" with heat transfer coefficient parameter from Cincotti and temperature of 293 K
#       T (elsewhere) --> natural boundary conditions
#    Mechanics (not added yet):
#       Displacement: --> pinned axial centerpoint along interior surface of powder block, outer die wall
#       Pressure: top and bottom surfaces of upper and lower rams, 20.7 MPa
#                 ramped quickly at simulation start, then held constant
# Interface Conditions:
#       V (SS-G upper and G-SS lower interface) --> ElectrostaticContactCondition
#       T (SS-G upper and G-SS lower interface) --> ThermalContactCondition
#       V (graphite-yttria and graphite-graphite) --> GapHeatTransfer
#       T (graphite-yttria and graphite-graphite) --> GapHeatTransfer
#       P (graphite-yttria and graphite-graphite) --> Mechanical Contact
# Initial Conditions:
#       V = default (0 V)
#       T = 293 K
# Applied Mechanical Load: needs to be updated to 6.5kN, was 3.5 kN
#
# Reference for graphite, stainless steel: Cincotti et al, DOI 10.1002/aic.11102
# Assorted references for yttria, listed as comments in input file

initial_temperature = 293 #roughly 600C where the pyrometer kicks in
#initial_porosity=0.36 #Maximum random jammed packing, Donev et al (2004) Science Magazine

[Mesh]
  file = ../../../meshes/drsinter_nodalcontact_2d.e
  coord_type = RZ
  construct_side_list_from_node_list = true
  patch_update_strategy = iteration
  patch_size = 20
  # ghosting_patch_size = 5*patch_size
[]

[Problem]
  type = ReferenceResidualProblem
  reference_vector = 'ref'
  extra_tag_vectors = 'ref'
[]

[Variables]
  [temperature_stainless_steel]
    initial_condition = ${initial_temperature}
    block = stainless_steel
  []
  [temperature]
    initial_condition = ${initial_temperature}
    block = 'graphite_spacers lower_plunger upper_plunger die_wall powder_compact'
  []
  [potential_stainless_steel]
    block = stainless_steel
  []
  [electric_potential]
    block = 'graphite_spacers lower_plunger upper_plunger die_wall powder_compact'
  []
[]

[AuxVariables]
  [electric_field_x]
    family = MONOMIAL #prettier pictures with smoother values
    order = FIRST
  []
  [electric_field_y]
    family = MONOMIAL
    order = FIRST
  []
  [current_density]
    family = NEDELEC_ONE
    order = FIRST
  []
  [yttria_sigma_aeh]
    initial_condition = 2.0e-10 #in units eV/((nV)^2-s-nm)
    block = 'powder_compact'
  []
  [microapp_potential]
    #converted to microapp electronVolts units
    block = 'powder_compact'
  []
  [E_x]
    order = FIRST
    family = MONOMIAL
    block = 'powder_compact'
  []
  [E_y]
    order = FIRST
    family = MONOMIAL
    block = 'powder_compact'
  []
  [yttria_current_density_forBC_microapp]
    order = FIRST
    family = MONOMIAL
    block = 'powder_compact'
  []

  # [T_infinity]
  #   initial_condition = ${initial_temperature}
  # []
  [heatflux_graphite_x]
    family = MONOMIAL
    order = CONSTANT
    block = 'graphite_spacers lower_plunger upper_plunger die_wall'
  []
  [heatflux_graphite_y]
    family = MONOMIAL
    order = CONSTANT
    block = 'graphite_spacers lower_plunger upper_plunger die_wall'
  []
  [heatflux_stainless_steel_x]
    family = MONOMIAL
    order = CONSTANT
    block = stainless_steel
  []
  [heatflux_stainless_steel_y]
    family = MONOMIAL
    order = CONSTANT
    block = stainless_steel
  []
  [heatflux_yttria_x]
    family = MONOMIAL
    order = CONSTANT
    block = 'powder_compact'
  []
  [heatflux_yttria_y]
    family = MONOMIAL
    order = CONSTANT
    block = 'powder_compact'
  []
  [yttria_thermal_conductivity_aeh]
    initial_condition = 0.4
  []
  [yttria_heat_capacity_volume_avg]
    initial_condition = 447.281 #842.2 at 1600K probably? # at 1500K #568.73 at 1000K #447.281 # at 293K
  []
  [yttria_density_volume_avg]
    initial_condition = 3206.4 ##5010.0*(1-${initial_porosity}) #in kg/m^3
  []
  [heat_transfer_radiation]
  []
  # [thermal_conductivity]
  #   family = MONOMIAL
  #   order = FIRST
  # []
[]

[Kernels]
  [HeatDiff_graphite]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = thermal_conductivity
    extra_vector_tags = 'ref'
    block = 'graphite_spacers lower_plunger upper_plunger die_wall'
  []
  [HeatTdot_graphite]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = heat_capacity
    density_name = density
    extra_vector_tags = 'ref'
    block = 'graphite_spacers lower_plunger upper_plunger die_wall'
  []
  [JouleHeating_graphite]
    type = ADJouleHeatingSource
    variable = temperature
    elec = electric_potential
    electrical_conductivity = electrical_conductivity
    use_displaced_mesh = true
    extra_vector_tags = 'ref'
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [electric_graphite]
    type = ADMatDiffusion
    variable = electric_potential
    diffusivity = electrical_conductivity
    extra_vector_tags = 'ref'
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []

  [HeatDiff_stainless_steel]
    type = ADHeatConduction
    variable = temperature_stainless_steel
    thermal_conductivity = thermal_conductivity
    extra_vector_tags = 'ref'
    block = stainless_steel
  []
  [HeatTdot_stainless_steel]
    type = ADHeatConductionTimeDerivative
    variable = temperature_stainless_steel
    specific_heat = heat_capacity
    density_name = density
    extra_vector_tags = 'ref'
    block = stainless_steel
  []
  [HeatSource_stainless_steel]
    type = ADJouleHeatingSource
    variable = temperature_stainless_steel
    elec = potential_stainless_steel
    electrical_conductivity = electrical_conductivity
    use_displaced_mesh = true
    extra_vector_tags = 'ref'
    block = stainless_steel
  []
  [electric_stainless_steel]
    type = ADMatDiffusion
    variable = potential_stainless_steel
    diffusivity = electrical_conductivity
    extra_vector_tags = 'ref'
    block = stainless_steel
  []

  [HeatDiff_yttria]
    type = ADHeatConduction
    variable = temperature
    thermal_conductivity = thermal_conductivity #use parsed material property, hope it works
    extra_vector_tags = 'ref'
    block = powder_compact
  []
  [HeatTdot_yttria]
    type = ADHeatConductionTimeDerivative
    variable = temperature
    specific_heat = heat_capacity #use parsed material property
    density_name = density
    extra_vector_tags = 'ref'
    block = powder_compact
  []
  [JouleHeating_yttria]
    type = ADJouleHeatingSource
    variable = temperature
    elec = electric_potential
    electrical_conductivity = electrical_conductivity
    use_displaced_mesh = true
    extra_vector_tags = 'ref'
    block = powder_compact
  []
  [electric_yttria]
    type = ADMatDiffusion
    variable = electric_potential
    diffusivity = electrical_conductivity
    extra_vector_tags = 'ref'
    block = powder_compact
  []
[]

[AuxKernels]
  [electrostatic_calculation_x_graphite_yttria]
    type = PotentialToFieldAux
    gradient_variable = electric_potential
    variable = electric_field_x
    sign = negative
    component = x
    block = 'powder_compact graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [electrostatic_calculation_y_graphite_yttria]
    type = PotentialToFieldAux
    gradient_variable = electric_potential
    variable = electric_field_y
    sign = negative
    component = y
    block = 'powder_compact graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [electrostatic_calculation_x_stainless_steel]
    type = PotentialToFieldAux
    gradient_variable = potential_stainless_steel
    variable = electric_field_x
    sign = negative
    component = x
    block = stainless_steel
  []
  [electrostatic_calculation_y_stainless_steel]
    type = PotentialToFieldAux
    gradient_variable = potential_stainless_steel
    variable = electric_field_y
    sign = negative
    component = y
    block = stainless_steel
  []
  [current_density_graphite_yttria]
    type = ADCurrentDensity
    variable = current_density
    potential = electric_potential
    block = 'powder_compact graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [current_density_stainless_steel]
    type = ADCurrentDensity
    variable = current_density
    potential = potential_stainless_steel
    block = stainless_steel
  []
  [microapp_potential]
    type = ParsedAux
    variable = microapp_potential
    coupled_variables = electric_potential
    expression = 'electric_potential*1e9' #convert from V to nV
    block = 'powder_compact'
  []
  [E_x]
    type = VariableGradientComponent
    variable = E_x
    gradient_variable = electric_potential
    component = x
    block = 'powder_compact'
  []
  [E_y]
    type = VariableGradientComponent
    variable = E_y
    gradient_variable = electric_potential
    component = y
    block = 'powder_compact'
  []
  [yttria_current_density_forBC_microapp]
    type = ParsedAux
    variable = yttria_current_density_forBC_microapp
    coupled_variables = 'electrical_conductivity E_y'
    expression = '-1.0*electrical_conductivity*E_y'
    block = 'powder_compact'
  []

  [heat_flux_graphite_x]
    type = DiffusionFluxAux
    diffusivity = nonad_thermal_conductivity
    diffusion_variable = temperature
    variable = heatflux_graphite_x
    component = x
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [heat_flux_graphite_y]
    type = DiffusionFluxAux
    diffusivity = nonad_thermal_conductivity
    diffusion_variable = temperature
    variable = heatflux_graphite_y
    component = y
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [heat_flux_stainless_x]
    type = DiffusionFluxAux
    diffusivity = nonad_thermal_conductivity
    diffusion_variable = temperature_stainless_steel
    variable = heatflux_stainless_steel_x
    block = stainless_steel
    component = x
  []
  [heat_flux_stainless_y]
    type = DiffusionFluxAux
    diffusivity = nonad_thermal_conductivity
    diffusion_variable = temperature_stainless_steel
    variable = heatflux_stainless_steel_y
    block = stainless_steel
    component = y
  []
  [heat_flux_yttria_x]
    type = DiffusionFluxAux
    diffusivity = nonad_thermal_conductivity
    diffusion_variable = temperature
    variable = heatflux_yttria_x
    component = x
    block = 'powder_compact'
  []
  [heat_flux_yttria_y]
    type = DiffusionFluxAux
    diffusivity = nonad_thermal_conductivity
    diffusion_variable = temperature
    variable = heatflux_yttria_y
    component = y
    block = 'powder_compact'
  []

  [heat_transfer_radiation_graphite]
    type = ParsedAux
    variable = heat_transfer_radiation
    boundary = 'outer_radiative_spacers outer_die_wall radiative_upper_plunger radiative_lower_plunger'
    coupled_variables = 'temperature'
    constant_names = 'boltzmann epsilon temperature_farfield' #published emissivity for graphite is 0.85
    constant_expressions = '5.67e-8 0.85 293.0' #roughly room temperature, which is probably too cold
    expression = '-boltzmann*epsilon*(temperature^4-temperature_farfield^4)'
  []
  [heat_transfer_radiation_stainless_steel]
    type = ParsedAux
    variable = heat_transfer_radiation
    boundary = 'outer_radiative_stainless_steel'
    coupled_variables = 'temperature'
    constant_names = 'boltzmann epsilon temperature_farfield' #published emissivity for graphite is 0.85
    constant_expressions = '5.67e-8 0.4 293.0' #roughly room temperature, which is probably too cold
    expression = '-boltzmann*epsilon*(temperature^4-temperature_farfield^4)'
  []
  [thermal_conductivity_graphite]
    type = ADMaterialRealAux
    variable = thermal_conductivity
    property = thermal_conductivity
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [thermal_conductivity_steel]
    type = ADMaterialRealAux
    variable = thermal_conductivity
    property = thermal_conductivity
    block = 'stainless_steel'
  []
  [thermal_conductivity_yttria]
    type = ADMaterialRealAux
    variable = thermal_conductivity
    property = thermal_conductivity
    block = 'powder_compact'
  []
  [electrical_conductivity_graphite]
    type = ADMaterialRealAux
    variable = electrical_conductivity
    property = electrical_conductivity
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [electrical_conductivity_steel]
    type = ADMaterialRealAux
    variable = electrical_conductivity
    property = electrical_conductivity
    block = 'stainless_steel'
  []
  [electrical_conductivity_yttria]
    type = ADMaterialRealAux
    variable = electrical_conductivity
    property = electrical_conductivity
    block = 'powder_compact'
  []
[]

[BCs]
  [external_surface_stainless]
    type = CoupledVarNeumannBC
    boundary = 'outer_radiative_stainless_steel'
    variable = temperature_stainless_steel
    v = heat_transfer_radiation
  []
  [external_surface_graphite]
    type = CoupledVarNeumannBC
    boundary = 'outer_radiative_spacers outer_die_wall radiative_upper_plunger radiative_lower_plunger'
    variable = temperature
    v = heat_transfer_radiation
  []
  [water_channel]
    type = CoupledConvectiveHeatFluxBC
    boundary = water_channel
    variable = temperature_stainless_steel
    T_infinity = ${initial_temperature}
    htc = 4725
  []
  [temperature_ram_extremes]
    type = ADDirichletBC
    variable = temperature_stainless_steel
    boundary = 'top_upper_steel_ram bottom_lower_steel_ram'
    value = 293
  []
  [electric_potential_top]
    type = ADFunctionNeumannBC
    variable = potential_stainless_steel
    boundary = top_upper_steel_ram
    ## This will need to be updated to match the Dr. Sinter geometry
    function = 'if(t < 31, (980 / (pi * 0.00155))*((0.141301/4.3625)*t), if(t > 600, 0, 980 / (pi * 0.00155)))' # RMS Current / Cross-sectional Area. Ramping for t < 31s approximately reflects Cincotti et al (DOI: 10.1002/aic.11102) Figure 21(b)
  []
  [electric_potential_bottom]
    type = ADDirichletBC
    variable = potential_stainless_steel
    boundary = bottom_lower_steel_ram
    value = 0
  []
[]

[Functions]
  [graphite_thermal_conductivity_fcn]
    type = ParsedFunction
    expression = '-4.418e-12*t^4+2.904e-8*t^3-4.688e-5*t^2-0.0316*t+119.659'
  []
  # [yttria_thermal_conductivity_fcn] #from the multiapp
  #   type = ParsedFunction
  #   expression = '3214.46/(t-147.73)'
  # []
  [harmonic_mean_thermal_conductivity]
    type = ParsedFunction
    expression = '2*(-4.418e-12*t^4+2.904e-8*t^3-4.688e-5*t^2-0.0316*t+119.659)*(3214.46/(t-147.73))/((-4.418e-12*t^4+2.904e-8*t^3-4.688e-5*t^2-0.0316*t+119.659)+(3214.46/(t-147.73)))'
    # symbol_names = 'k_graphite k_yttria'
    # symbol_values = 'graphite_thermal_conductivity_fcn yttria_thermal_conductivity_fcn'
  []

  [graphite_electrical_conductivity_fcn]
    type = ParsedFunction
    expression = '1.0/(-2.705e-15*t^3+1.263e-11*t^2-1.836e-8*t+1.813e-5)'
  []
  # [electrical_conductivity_fcn]
  #   type = ParsedFunction
  #   # symbol_names = porosity
  #   # symbol_values = initial_porosity
  #   expression = '(1-0.62)*2.0025e4*exp(-1.61/8.617343e-5/t)'
  # []
  [harmonic_mean_electrical_conductivity]
    type = ParsedFunction
    expression = '2*(1.0/(-2.705e-15*t^3+1.263e-11*t^2-1.836e-8*t+1.813e-5))*((1)*2.0025e4*exp(-1.61/8.617343e-5/t))/((1.0/(-2.705e-15*t^3+1.263e-11*t^2-1.836e-8*t+1.813e-5))+((1)*2.0025e4*exp(-1.61/8.617343e-5/t)))'
    # symbol_names = 'k_graphite k_yttria'
    # symbol_values = 'graphite_thermal_conductivity_fcn yttria_thermal_conductivity_fcn'
  []
  [mechanical_pressure_func]
    type = ParsedFunction
    symbol_names = 'radius force'
    symbol_values = '0.04 6.5' # 'm kN'
    expression = 'force * 1e3 / (pi * radius^2)' # (N / m^2)
  []
[]

[InterfaceKernels]
  [electric_contact_conductance_ssg]
    type = ElectrostaticContactCondition
    variable = potential_stainless_steel
    neighbor_var = electric_potential
    boundary = 'upper_ram_spacer_interface lower_ram_spacer_interface'
    mean_hardness = graphite_stainless_mean_hardness
    mechanical_pressure = mechanical_pressure_func
  []
  [thermal_contact_conductance_calculated_ssg]
    type = ThermalContactCondition
    variable = temperature_stainless_steel
    neighbor_var = temperature
    primary_potential = potential_stainless_steel
    secondary_potential = electric_potential
    primary_thermal_conductivity = thermal_conductivity
    secondary_thermal_conductivity = thermal_conductivity
    primary_electrical_conductivity = electrical_conductivity
    secondary_electrical_conductivity = electrical_conductivity
    mean_hardness = graphite_stainless_mean_hardness
    mechanical_pressure = mechanical_pressure_func
    boundary = 'upper_ram_spacer_interface lower_ram_spacer_interface'
  []
  [electric_contact_conductance_gss]
    type = ElectrostaticContactCondition
    variable = electric_potential
    neighbor_var = potential_stainless_steel
    boundary = 'upper_ram_spacer_interface lower_ram_spacer_interface'
    mean_hardness = graphite_stainless_mean_hardness
    mechanical_pressure = mechanical_pressure_func
  []
  [thermal_contact_conductance_calculated_gss]
    type = ThermalContactCondition
    variable = temperature
    neighbor_var = temperature_stainless_steel
    primary_potential = electric_potential
    secondary_potential = potential_stainless_steel
    primary_thermal_conductivity = thermal_conductivity
    secondary_thermal_conductivity = thermal_conductivity
    primary_electrical_conductivity = electrical_conductivity
    secondary_electrical_conductivity = electrical_conductivity
    mean_hardness = graphite_stainless_mean_hardness
    mechanical_pressure = mechanical_pressure_func
    boundary = 'upper_ram_spacer_interface lower_ram_spacer_interface'
  []
[]

[ThermalContact]
  [upper_plunger_powder_electric]
    type = GapHeatTransfer
    primary = bottom_upper_plunger
    secondary = top_powder_compact
    variable = electric_potential
    quadrature = true
    emissivity_primary = 0.0 #not applicable for electric potential
    emissivity_secondary = 0.0 #not applicable for electric potential
    gap_geometry_type = PLATE
    # gap_conductivity = 1e-23 #rough harmonic mean
    gap_conductivity_function = 'harmonic_mean_electrical_conductivity'
    gap_conductivity_function_variable = temperature
    normal_smoothing_distance = 0.1
  []
  [powder_bottom_plunger_electric]
    type = GapHeatTransfer
    primary = top_lower_plunger
    secondary = bottom_powder_compact
    variable = electric_potential
    quadrature = true
    emissivity_primary = 0.0 #not applicable for electric potential
    emissivity_secondary = 0.0 #not applicable for electric potential
    gap_geometry_type = PLATE
    # gap_conductivity = 1e-23 #rough harmonic mean
    gap_conductivity_function = 'harmonic_mean_electrical_conductivity'
    gap_conductivity_function_variable = temperature
    normal_smoothing_distance = 0.1
  []
  [combined_plungers_die_electric]
    #to reproduce a more symmetric temperature profile, move this block to the bottom of this ThermalContact section
    type = GapHeatTransfer
    primary = inner_die_wall
    secondary = combined_outer_plungers
    variable = electric_potential
    quadrature = true
    emissivity_primary = 0.0 #not applicable for electric potential
    emissivity_secondary = 0.0 #not applicable for electric potential
    # gap_geometry_type = PLATE # Not for vertical surfaces
    # gap_conductivity = 8.5e4 #graphite, at 500K
    gap_conductivity_function = 'graphite_electrical_conductivity_fcn'
    gap_conductivity_function_variable = temperature
    normal_smoothing_distance = 0.1
    # appended_property_name = plungers
  []
  [powder_die_electric]
    type = GapHeatTransfer
    primary = inner_die_wall
    secondary = outer_powder_compact
    variable = electric_potential
    quadrature = true
    emissivity_primary = 0.0 #0.85 #cincotti 2007, table 2
    emissivity_secondary = 0.0 #0.85
    # gap_geometry_type = PLATE # Not for vertical surfaces
    # gap_conductivity = 1e-23 #rough harmonic mean
    gap_conductivity_function = 'harmonic_mean_electrical_conductivity'
    gap_conductivity_function_variable = temperature
    normal_smoothing_distance = 0.1
    # appended_property_name = powder
  []
[]

# ## Thermal Contact between touching components of powder and die
# [ThermalContact]
# [lower_plunger_die_thermal]
#   type = GapHeatTransfer
#   primary = inner_die_wall
#   secondary = outer_lower_plunger
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   # gap_geometry_type = PLATE # Not for vertical surfaces
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [top_plunger_die_thermal]
#   type = GapHeatTransfer
#   primary = inner_die_wall
#   secondary = outer_upper_plunger
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   # gap_geometry_type = PLATE # Not for vertical surfaces
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [upper_plunger_powder_thermal]
#   type = GapHeatTransfer
#   primary = bottom_upper_plunger
#   secondary = top_powder_compact
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   gap_geometry_type = PLATE
#   gap_conductivity_function = 'harmonic_mean_thermal_conductivity'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [powder_die_thermal]
#   type = GapHeatTransfer
#   primary = inner_die_wall
#   secondary = outer_powder_compact
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.3 #estimated from McMahon and Wilder, High Temperature Spectral Emissivity of Yttrium, Samarium, Gadolinium, Ebrium and Lutetium Oxides (1963) Atomic Energy Commission, IS-578, Figure 12
#   # gap_geometry_type = PLATE # Not for vertical surfaces
#   gap_conductivity_function = 'harmonic_mean_thermal_conductivity'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [powder_bottom_plunger_thermal]
#   type = GapHeatTransfer
#   primary = top_lower_plunger
#   secondary = bottom_powder_compact #expect more heat transfer from the die to the powder
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.3 #estimated from McMahon and Wilder, High Temperature Spectral Emissivity of Yttrium, Samarium, Gadolinium, Ebrium and Lutetium Oxides (1963) Atomic Energy Commission, IS-578, Figure 12
#   gap_geometry_type = PLATE
#   gap_conductivity_function = 'harmonic_mean_thermal_conductivity'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []

# ##Thermal Contact between gapped graphite die components
# [lower_plunger_spacer_gap_thermal]
#   type = GapHeatTransfer
#   primary = spacer_facing_lower_plunger
#   secondary = plunger_facing_lower_spacer
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   gap_geometry_type = PLATE
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [lower_plunger_diewall_gap_thermal]
#   type = GapHeatTransfer
#   primary = die_wall_facing_lower_plunger
#   secondary = inner_die_wall
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   # gap_geometry_type = PLATE # Not for vertical surfaces
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [lower_diewall_spacer_gap_thermal]
#   type = GapHeatTransfer
#   primary = bottom_die_wall
#   secondary = top_lower_spacer
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   gap_geometry_type = PLATE
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [upper_plunger_spacer_gap_thermal]
#   type = GapHeatTransfer
#   primary = spacer_facing_upper_plunger
#   secondary = plunger_facing_upper_spacer
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   gap_geometry_type = PLATE
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [upper_plunger_diewall_gap_thermal]
#   type = GapHeatTransfer
#   primary = die_wall_facing_upper_plunger
#   secondary = inner_die_wall
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   # gap_geometry_type = PLATE # Not for vertical surfaces
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# [upper_diewall_spacer_gap_thermal]
#   type = GapHeatTransfer
#   primary = top_die_wall
#   secondary = bottom_upper_spacer
#   variable = temperature
#   quadrature = true
#   emissivity_primary = 0.85 #cincotti 2007, table 2
#   emissivity_secondary = 0.85
#   gap_geometry_type = PLATE
#   gap_conductivity_function = 'graphite_thermal_conductivity_fcn'
#   gap_conductivity_function_variable = temperature
#   normal_smoothing_distance = 0.1
# []
# []

[Materials]
  ## graphite blocks
  [graphite_thermal]
    type = ADGraphiteThermal
    temperature = temperature
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [graphite_density]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = 1.750e3 #in kg/m^3 from Cincotti et al 2007, Table 2, doi:10.1002/aic
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [graphite_electrical_conductivity]
    type = ADGraphiteElectricalConductivity
    temperature = temperature
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []

  #stainless_steel
  [stainless_steel_thermal]
    type = ADStainlessSteelThermal
    temperature = temperature_stainless_steel
    block = stainless_steel
  []
  [stainless_steel_density]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = 8000
    block = stainless_steel
  []
  [stainless_steel_electrical_conductivity]
    type = ADStainlessSteelElectricalConductivity
    temperature = temperature_stainless_steel
    block = stainless_steel
  []

  # harmonic mean of graphite and stainless steel hardness
  [mean_hardness_graphite_stainless_steel]
    type = GraphiteStainlessMeanHardness
    block = 'graphite_spacers upper_plunger lower_plunger die_wall stainless_steel'
  []

  ## yttria powder compact
  [yttria_thermal_conductivity]
    type = ADParsedMaterial
    coupled_variables = 'temperature'
    expression = '3214.46 / (temperature - 147.73)' #in W/(m-K) #Given from Larry's curve fitting, data from Klein and Croft, JAP, v. 38, p. 1603 and UC report "For Computer Heat Conduction Calculations - A compilation of thermal properties data" by A.L. Edwards, UCRL-50589 (1969)
    # coupled_variables = 'thermal_conductivity_aeh'
    # expression = 'thermal_conductivity_aeh' #in W/(m-K) directly, for now
    property_name = 'thermal_conductivity'
    output_properties = thermal_conductivity
    outputs = 'csv exodus'
    block = powder_compact
  []
  [yttria_specific_heat_capacity]
    type = ADParsedMaterial
    property_name = heat_capacity
    coupled_variables = 'yttria_heat_capacity_volume_avg'
    expression = 'yttria_heat_capacity_volume_avg' #in J/(K-kg)
    # output_properties = yttria_specific_heat_capacity
    # outputs = 'csv exodus'
    block = powder_compact
  []
  [yttria_density]
    type = ADParsedMaterial
    property_name = 'density'
    coupled_variables = 'yttria_density_volume_avg'
    expression = 'yttria_density_volume_avg'
    # output_properties = yttria_density
    # outputs = 'csv exodus'
    block = powder_compact
  []
  [electrical_conductivity]
    type = ADParsedMaterial
    #   coupled_variables = 'yttria_sigma_aeh'
    #   expression = 'yttria_sigma_aeh*1.602e8' #converts to units of J/(V^2-m-s)
    property_name = 'electrical_conductivity'
    output_properties = electrical_conductivity
    outputs = 'exodus csv'
    block = powder_compact
    # type = ADDerivativeParsedMaterial
    # property_name = electrical_conductivity
    coupled_variables = 'temperature'
    constant_names =       'Q_elec  kB            prefactor_solid  initial_porosity'
    constant_expressions = '1.61    8.617343e-5        1.25e-4           0.38'
    expression = '(1-initial_porosity) * prefactor_solid * exp(-Q_elec/kB/temperature) * 1.602e8' # in eV/(nV^2 s nm) per chat with Larry, last term converts to units of J/(V^2-m-s)
  []

  # Material property converter for DiffusionFluxAux object
  [converter]
    type = MaterialADConverter
    ad_props_in = thermal_conductivity
    reg_props_out = nonad_thermal_conductivity
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  automatic_scaling = true
  line_search = 'none'
  # compute_scaling_once = false

  # force running options
  # petsc_options_iname = '-pc_type -snes_linesearch_type -pc_factor_shift_type -pc_factor_shift_amount'
  # petsc_options_value = 'lu       basic                 NONZERO               1e-15'

  # #mechanical contact options
  # petsc_options = '-snes_ksp_ew'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = ' lu       superlu_dist'
  petsc_options = '-snes_converged_reason -ksp_converged_reason'

  nl_forced_its = 1
  nl_rel_tol = 2e-5 #1e-6 #2e-5 for with mechanics #was 1e-10, for temperature only
  nl_abs_tol = 2e-12 #was 1e-12
  nl_max_its = 20
  l_max_its = 50
  dtmin = 1.0e-4

  # num_steps = 1
  end_time = 50 #600 #900 #15 minutes, rule of thumb from Dennis is 10 minutes
  [Quadrature]
    order = FIFTH #required for thermal and mechanical node-face contact
    side_order = SEVENTH
  []
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.05
    optimal_iterations = 8
    iteration_window = 2
  []
[]

[Postprocessors]
  [temperature_pp]
    type = AverageNodalVariableValue
    variable = temperature
    block = 'graphite_spacers upper_plunger lower_plunger die_wall powder_compact'
  []
  [temperature_stainless_steel_pp]
    type = AverageNodalVariableValue
    variable = temperature_stainless_steel
    block = stainless_steel
  []
  [graphite_thermal_conductivity]
    type = ElementAverageValue
    variable = thermal_conductivity
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [graphite_electrical_conductivity]
    type = ElementAverageValue
    variable = electrical_conductivity
    block = 'graphite_spacers upper_plunger lower_plunger die_wall'
  []
  [steel_thermal_conductivity]
    type = ElementAverageValue
    variable = thermal_conductivity
    block = stainless_steel
  []
  [steel_electrical_conductivity]
    type = ElementAverageValue
    variable = electrical_conductivity
    block = stainless_steel
  []
  [yttria_thermal_conductivity]
    type = ElementAverageValue
    variable = thermal_conductivity
    block = powder_compact
  []
  [yttria_electrical_conductivity]
    type = ElementAverageValue
    variable = electrical_conductivity
    block = powder_compact
  []
[]

[Outputs]
  csv = true
  exodus = true
  perf_graph = true
  # [ckpt]
  #   type =Checkpoint
  #   time_step_interval = 1
  #   num_files = 2
  # []
[]
