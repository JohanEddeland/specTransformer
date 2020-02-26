function thisRelBlock = resetCounterToSTL(obj, component)
%FUNCTION   Description goes here.
%

% IMPORTANT!
% This function is SIMPLIFIED and only uses ONE value for Inc (the maximum
% of all possible Inc values)!!!

inputNames = obj.getInputNames(component);

[rStartDelay, rEndDelay, rDepth, rModalDepth, FPIstruct] = obj.getSubStructInfo(inputNames{1}); % r
% [rvVal, ~, ~, ~, ~] = obj.getSubStructInfo(inputNames{2}); % rv
[~, ~, ~, ~, FPIstruct3] = obj.getSubStructInfo(inputNames{3}); % Inc
% [maxVal, ~, ~, ~, ~] = obj.getSubStructInfo(inputNames{4}); % Max

% SIMPLIFIED: Find the maximum Inc parameter
% available
inc = 0;
for tmpIndex=1:length(FPIstruct3)
    tmpInc = evalin('base',FPIstruct3(tmpIndex).formula);
    inc = max(inc, tmpInc);
end

% IMPORTANT!!
% We can't set the output of THIS block to an STL
% formula. We must set the output of the parent
% block (a RelationalOperator block) to

% CASE 1: "<"
% ev_[0, timeTol*dt](r[t - timeTol*dt])

% CASE 2: ">"
% alw_[0, timeTol*dt](not(r[t - timeTol*dt]))

% CASE 3: '~= 0'
% not(r[t])

% CASE 4: '== 0'
% r[t]

% Loop over all blocks connected to the output of
% the CounterResetMax



% There can be several "components"
% connected to this one outport
%component = componentCell(kComponent);
relBlocks = obj.parentHandle(obj.systemHandle == component);

% Find one that has no output set to it!
for relBlockCounter = 1:length(relBlocks)
    thisRelBlock = relBlocks(relBlockCounter);
    thisRelBlockName = get(thisRelBlock, 'OutputSignalName');
    if isempty(thisRelBlockName{1})
        % The output name has not been set
        % Use this block
        break;
    end
end



% Assert that the "new" component is actually a relational
% operator!
if ~strcmp(get(thisRelBlock, 'BlockType'), 'RelationalOperator')
    % The new component is not a relational operator block
    obj.logOneBlock(component, 'Cannot create STL formula for resetCounter when it is not connected to a relational opreator block');
    
    % Set the returned thisRelBlock to be the parent, since we have now
    % logged this block and shouldn't try to create an STL formula for it
    % again. 
    thisRelBlock = obj.parentHandle(obj.systemHandle == component);
    return
end

RelOperatorConn = get(thisRelBlock,'PortConnectivity');

RelOperatorPH = get(thisRelBlock, 'PortHandles');
%src = component;
inpNamesTmp = get(thisRelBlock, 'InputSignalNames');
if isempty(inpNamesTmp{2})
    % Option 1: Input 2 to the relational operator
    % has not been set. We assume that it is just
    % connected to a constant!
    constantBlock = RelOperatorConn(2).SrcBlock;
    maxVal = evalin('base',get(constantBlock,'Value'));
else
    % Option 2: Input 2 to the relational operator has
    % already been set. We find the value!
    [~,~,~,~,FPIstruct2] = obj.getSubStructInfo(inpNamesTmp{2});
    maxVal = evalin('base',FPIstruct2(1).formula);
end

% Calculate the time tolerance (max/inc)
timeTol = maxVal/inc;

for tmpIndex=1:length(FPIstruct)
    
    switch get(thisRelBlock, 'Operator')
        case '<'
            % Old implementation using future operators
            % ev_[0, (timeTol-1)*dt](r[t - (timeTol-1)*dt]) or (t < maxVal)
            % rShifted = obj.shiftTimeBackwards(rVal(endOfFirst:startOfNext-1), num2str(timeTol-1));
            % FPIstruct(tmpIndex).formula = ['ev_[0,' num2str(timeTol-1) '*dt](' rShifted ') or (t < ' num2str(maxVal) ')'];
            % rVal = [rVal(1:endOfFirst-1) '(ev_[0,' num2str(timeTol-1) '*dt](' rShifted ') or (t < ' num2str(maxVal) '))' rVal(startOfNext:end)];

            % New implementation with past operators
            FPIstruct(tmpIndex).formula = ['once_[0,' num2str(timeTol-1) '*dt](' FPIstruct(tmpIndex).formula ')'];
            
            startDelay = rStartDelay + timeTol - 1;
            depth = rDepth + 2;
            modalDepth = rModalDepth + 1;
        case '<='
            % Old implementation using future operators
            % ev_[0, timeTol*dt](r[t - timeTol*dt]) or (t <= maxVal)
            % rShifted = obj.shiftTimeBackwards(rVal(endOfFirst:startOfNext-1), num2str(timeTol));
            % FPIstruct(tmpIndex).formula = ['ev_[0,' num2str(timeTol-1) '*dt](' rShifted ') or (t <= ' num2str(maxVal) ')'];
            % rVal = [rVal(1:endOfFirst-1) '(ev_[0,' num2str(timeTol-1) '*dt](' rShifted ') or (t <= ' num2str(maxVal) '))' rVal(startOfNext:end)];
            
            % New implementation with past operators
            FPIstruct(tmpIndex).formula = ['once_[0,' num2str(timeTol) '*dt](' FPIstruct(tmpIndex).formula ')'];
            
            startDelay = rStartDelay + timeTol;
            depth = rDepth + 2;
            modalDepth = rModalDepth + 1;
        case '>'
            % Old implementation using future operators
            % alw_[0, (timeTol-1)*dt](not(r[t - (timeTol-1)*dt])) and (t > maxVal)
            % rShifted = obj.shiftTimeBackwards(rVal(endOfFirst:startOfNext-1), num2str(timeTol-1));
            % FPIstruct(tmpIndex).formula = ['alw_[0,' num2str(timeTol-1) '*dt](not(' rShifted ')) and (t > ' num2str(maxVal) ')'];
            % rVal = [rVal(1:endOfFirst-1) '(alw_[0,' num2str(timeTol-1) '*dt](not(' rShifted ')) and (t > ' num2str(maxVal) '))' rVal(startOfNext:end)];
            
            % New implementation with past operators
            FPIstruct(tmpIndex).formula = ['hist_[0,' num2str(timeTol-1) '*dt](not(' FPIstruct(tmpIndex).formula '))'];
            
            startDelay = rStartDelay + timeTol - 1;
            depth = rDepth + 3;
            modalDepth = rModalDepth + 1;
        case '>='
            % Old implementation using future operators
            % alw_[0, timeTol*dt](not(r[t - timeTol*dt])) and (t >= maxVal)
            % rShifted = obj.shiftTimeBackwards(rVal(endOfFirst:startOfNext-1), num2str(timeTol));
            % FPIstruct(tmpIndex).formula = ['alw_[0,' num2str(timeTol) '*dt](not(' rShifted ')) and (t >= ' num2str(maxVal) ')'];
            % rVal = [rVal(1:endOfFirst-1) '(alw_[0,' num2str(timeTol) '*dt](not(' rShifted ')) and (t >= ' num2str(maxVal) '))' rVal(startOfNext:end)];
            
            % New implementation with past operators
            FPIstruct(tmpIndex).formula = ['hist_[0,' num2str(timeTol) '*dt](not(' FPIstruct(tmpIndex).formula '))'];
            
            startDelay = rStartDelay + timeTol;
            depth = rDepth + 3;
            modalDepth = rModalDepth + 1;
        case '~='
            % TODO: Confirm that this is correct!
            % Same as for '<'
            
            % Old implementation using future operators
            % rShifted = obj.shiftTimeBackwards(rVal(endOfFirst:startOfNext-1), num2str(timeTol-1));
            % FPIstruct(tmpIndex).formula = ['ev_[0,' num2str(timeTol-1) '*dt](' rShifted ')'];
            % rVal = [rVal(1:endOfFirst-1) '(ev_[0,' num2str(timeTol-1) '*dt](' rShifted '))' rVal(startOfNext:end)];
            
            % New implementation with past operators
            FPIstruct(tmpIndex).formula = ['once_[0,' num2str(timeTol-1) '*dt](' FPIstruct(tmpIndex).formula ')'];
            
            startDelay = rStartDelay + timeTol - 1;
            depth = rDepth + 1;
            modalDepth = rModalDepth + 1;
        case '=='
            % TODO: Confirm that this is correct!
            % Same as for '>='
            
            % Old implementation using future operators
            % rShifted = obj.shiftTimeBackwards(rVal(endOfFirst:startOfNext-1), num2str(timeTol));
            % FPIstruct(tmpIndex).formula = ['alw_[0,' num2str(timeTol) '*dt](not(' rShifted ')) and (t >= ' num2str(maxVal) ')'];
            % rVal = [rVal(1:endOfFirst-1) '(alw_[0,' num2str(timeTol) '*dt](not(' rShifted ')) and (t >= ' num2str(maxVal) '))' rVal(startOfNext:end)];
            
            % New implementation with past operators
            FPIstruct(tmpIndex).formula = ['hist_[0,' num2str(timeTol) '*dt](not(' FPIstruct(tmpIndex).formula '))'];
            
            startDelay = rStartDelay + timeTol;
            depth = rDepth + 3;
            modalDepth = rModalDepth + 1;
        otherwise
            error('Unknown operator in the parent to resetCounter')
    end
    
end

% Set outportHandle to the outport of the
% relational operator block!
outportHandle = RelOperatorPH.Outport;
set(outportHandle,'Name',['sub' num2str(obj.subCounter)]);

updateStruct = struct();
updateStruct.startDelay = startDelay;
updateStruct.endDelay = rEndDelay;
updateStruct.depth = depth;
updateStruct.modalDepth = modalDepth;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = thisRelBlock;
obj.updateSubStructAndFormulaString(updateStruct);
end

