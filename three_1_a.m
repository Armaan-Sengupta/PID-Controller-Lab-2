clc; clear; close all;
% --- CONFIG ----
model_PD = 'PD_controller';  % <-- replace with your model name (the file that contains Figure 2)
model_distrubance = 'PD_w_disturbance';
baseDir = fileparts(mfilename('fullpath'));
cases  = {'2-1a','2-1b','2-1b'};     % will run all and make three figures
% ----------------

for k = 1:numel(cases)
    caseName = cases{k};
    % Convert folder name (e.g., 2-1a → 2_1a.mat)
    fileName = [strrep(caseName,'-','_') '.mat'];
    
    % Build full path
    dataFile = fullfile(baseDir, 'MTE360-Lab2-Group6-V2', caseName, fileName);

    % 1) Load lab data
    S = load(dataFile);             % expects Xr, X, U; each N×2: [time value]
    Xr = S.Xr;  X = S.X;  U = S.U;  % time in col 1, data in col 2
    E_lab = Xr(:,2) - X(:,2);

    % 2) Prepare reference input for Simulink Inport "xr_simin"
    xr_simin = timeseries(Xr(:,2), Xr(:,1));
    xr_simin.TimeInfo.Units = 'seconds';
    assignin('base','xr_simin',xr_simin);  % the Inport block named xr_simin will read this

    % 3) Run Simulink for the same time span as the data
    stopTime = num2str(Xr(end,1));
    if k ~= 3
        figure_title = ['MTE360 3.1a – ' caseName];
        load_system(model_PD);
        simOut   = sim(model_PD, 'StopTime', stopTime, 'ReturnWorkspaceOutputs', 'on');
    else
        figure_title = ['MTE360 3.1f – ' caseName];
        load_system(model_distrubance);
        simOut   = sim(model_distrubance, 'StopTime', stopTime, 'ReturnWorkspaceOutputs', 'on');
    end

    % 4) Extract logged signals (N×2: [t  value])
    x_sim  = simOut.x_sim;
    xr_sim = simOut.xr_sim;   % we will use this one for reference
    e_sim  = simOut.e_sim;
    u_sim  = simOut.u_sim;
    
    tS = x_sim(:,1);   % simulation time
    tL = X(:,1);       % lab time
    
    % 5) Dark figure and three stacked axes
    f  = figure('Name',figure_title , 'Color','k', ...
                'Position',[100 100 1100 800]);
    tl = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
    title(tl,'MTE360 – Section 3.1a Overlay','Color','w','FontWeight','normal');
    
    darken = @(ax) set(ax, 'Color','k','XColor','w','YColor','w', ...
                            'GridColor',[0.35 0.35 0.35], 'MinorGridColor',[0.25 0.25 0.25]);
    
    %% Top: Position (plot reference once)
    ax1 = nexttile; hold(ax1,'on');
    plot(tS, xr_sim(:,2), '--', 'Color',[0 1 0], 'LineWidth',1.6);   % reference in green
    plot(tS, x_sim(:,2),  'Color',[0 1 1], 'LineWidth',1.8);         % sim x in cyan
    plot(tL, X(:,2),      'Color',[1 0 1], 'LineWidth',1.2);         % lab x in magenta
    grid on; xlabel('t [s]'); ylabel('x [mm]'); title(['Position – ' caseName],'Color','w');
    legend({'x_r','x_{sim}','x_{lab}'},'Location','eastoutside','TextColor','w','Box','off');
    darken(ax1);
    
    %% Middle: Tracking Error
    ax2 = nexttile; hold(ax2,'on');
    plot(tS, e_sim(:,2), 'Color',[0 1 1], 'LineWidth',1.8);           % sim e in cyan
    plot(tL, E_lab,      'Color',[1 0 1], 'LineWidth',1.2);           % lab e in magenta
    grid on; xlabel('t [s]'); ylabel('e [mm]'); title('Tracking Error','Color','w');
    legend({'e_{sim}','e_{lab}'},'Location','eastoutside','TextColor','w','Box','off');
    darken(ax2);
    
    %% Bottom: Control Effort
    ax3 = nexttile; hold(ax3,'on');
    plot(tS, u_sim(:,2), 'Color',[0 1 1], 'LineWidth',1.8);           % sim u in cyan
    plot(tL, U(:,2),      'Color',[1 0 1], 'LineWidth',1.2);          % lab u in magenta
    grid on; xlabel('t [s]'); ylabel('u [V]'); title('Control Signal','Color','w');
    legend({'u_{sim}','u_{lab}'},'Location','eastoutside','TextColor','w','Box','off');
    darken(ax3);
    
    % Save
    if k ~= 3
        outPng = fullfile(baseDir, sprintf('MTE360_3_1a_%s_overlay.png',caseName));
    else
        outPng = fullfile(baseDir, sprintf('MTE360_3_1f_%s_overlay.png',caseName));
    end
    exportgraphics(f,outPng,'Resolution',300,'BackgroundColor','black');


end 

