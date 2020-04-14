function evChangesToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);
[~, ~, ~, ~, FPIstruct1, ~] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2, ~] = obj.getSubStructInfo(inputNames{2});
[startDelay3, endDelay3, depth3, modalDepth3, FPIstruct, inputType] = obj.getSubStructInfo(inputNames{3});

duration = evalin('base',FPIstruct1(1).formula);
assert(numel(FPIstruct1) == 1, 'We expect a constant as the duration to evChangesToSTL');

steptime = evalin('base',FPIstruct2(1).formula);
assert(numel(FPIstruct2) == 1, 'We expect a constant as the steptime to evChangesToSTL');

assert(duration > steptime, 'duration must be larger than tstep. Are the inputs in the wrong order?');


% Calculate the time tolerance
timeToHold = duration/steptime;

% In case the time tolerance is not an integer, it should be rounded down to
% be equivalent to semantics of evChanges block.
timeToHold = floor(timeToHold);

for tmpIndex=1:length(FPIstruct)
    inp3 = FPIstruct(tmpIndex).formula;
    shifted_inp3_one_dt = obj.shiftTimeBackwards(inp3, '1'); 
    % If inputType is signal_exp:
    % phi := ev_[0, timeToHold]((inp[t-thift] > inp[t-timeToHold-1]) or
    %   (inp[t-thift] < inp[t-thift-1]))
    % This is how it's implemented in the Simulink
    % blocks, HOWEVER this only works if inp is a
    % signal expression (see STL_Formula grammar, "<"
    % can only be used between signal expressions)
    
    % If inputType is phi_exp:
    % phi := ev_[0, timeToHold]((inp[t-timeToHold] and
    %   not(inp[t-timeToHold-1])) or (not(inp[t-timeToHold]) and
    %   inp[t-timeToHold-1]))
    % This formula works if inp is an STL Formula!
    % (phi_expr in STL_Formula grammar definition)
    if strcmp(inputType,'signal_exp')
        FPIstruct(tmpIndex).formula = ['(once_[0, ' num2str(timeToHold) '*dt](not(' inp3 ' == ' shifted_inp3_one_dt ')))'];
    else
        FPIstruct(tmpIndex).formula = ['(once_[0, ' num2str(timeToHold) '*dt]((' inp3 ' and not(' shifted_inp3_one_dt ')) or (not(' inp3 ') and ' shifted_inp3_one_dt ')))'];
    end
end

updateStruct = struct();
updateStruct.startDelay = startDelay3 + timeToHold;
updateStruct.endDelay = endDelay3;
updateStruct.depth = depth3 + 2;
updateStruct.modalDepth = modalDepth3 + 1;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct)

end

