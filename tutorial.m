%{
Tutorial for running a kinetochore microtubule binding simulation
%}

% choose initial parameters
num_time_steps = 5;
num_hec1 = 4;
tether_length = 10;
prob_bind=0.4; % related to k_bind
prob_unbind=1e-4; % related to k_unbind
binding_distance = 0.05;
num_dimers = 10;
dimer_length = 1;
hec1_step = 0.5; % length of each step taken by hec1 in random walk
mt_phosphor_params = [0.9, 0.9]; % microtubule phosphorylation probabilities
                                 % [p(phos|dephos), p(dephos|phos)]
e_params.S = 1e9; % spring constant for microtubule (0.38 - 2 GPa)
e_params.B = 7e-24; % bending rigidity for microtubule (7e-25 - 7e-23 Nm^2)
e_params.k = 1; % resting spring length between substrate and dimer
e_params.theta = 23; % preferred angle for gdp tubulin

% initialize the kinetochore and microtubule
[kinetochore, microtubule] = initialize_kmt(num_time_steps, num_hec1,...
    tether_length, num_dimers, dimer_length, mt_phosphor_params, e_params);


% let the microtubule curve and change phosphorylation state
microtubule.curve()
microtubule.phosphorylate()


% find new positions at next time step based on energy minimization
% TO DO: still need to make this a loop where phos state is updated in the
% loop and positions are calculated over time 

for tstep = 2
    
    phos_state = microtubule.phos_state(:, :, tstep);
    
    energy_function = minimizer_target(microtubule.e_params, num_dimers, phos_state);
    
    % create input vector of initial guess for positions (use previous
    % positions) -> need to reshape initial guess vector to be 1 row with
    % 2*num_dimers columns
    % guess(1:num_dimers) -> x values; guess(num_dimers+1, 2*num_dimers) -> y values
    init_guess = [microtubule.dimer_positions(1,:, tstep-1), microtubule.dimer_positions(2,:, tstep-1)];
    
    [pos, energy] = fminunc(energy_function, init_guess);
    microtubule.dimer_positions(:,:,tstep) = [pos(1:num_dimers); pos(num_dimers+1:end)];
end

disp('done')


plot_var = 0;
if plot_var == 1
    % plot the microtubule positions over time
    figure
    hold on
    for time_step=1:num_time_steps
        plot(microtubule.dimer_positions(1,:,time_step), microtubule.dimer_positions(2,:,time_step))
    end
    xlabel('x-position')
    ylabel('y-position')
    hold off
    
    % plot microtubule phosphorylation state over time
    figure
    hold on
    for time_step = 1 : num_time_steps
        plot(microtubule.phos_state(:, :, time_step))
    end
    xlabel('x-position')
    ylabel('phosphorylation state (0-GDP, 1-GTP)')
    hold off
    
    % let the kinetochore diffuse
    kinetochore.diffuse_bind_unbind(microtubule,prob_bind, prob_unbind, binding_distance, hec1_step)
    
    % plot the trajectories of the hec1 proteins
    figure
    for hec1=1:num_hec1
        x = reshape(kinetochore.hec1_positions(1,hec1,:),[1,5]);
        y = reshape(kinetochore.hec1_positions(2,hec1,:),[1,5]);
        z = reshape(kinetochore.hec1_positions(3,hec1,:),[1,5]);
        plot3(x, y, z)
        hold on
    end
    hold off
    title('time course tracks of hec1 molecules')
    % TODO: let the kinetochore bind and unbind
    
    % calculate the fraction bound for each time step
    fraction_bound = kinetochore.calc_fraction_bound();
    
    % plot the fraction bound over time
    figure
    plot(fraction_bound)
    xlabel('time')
    ylabel('bound fraction')
end
