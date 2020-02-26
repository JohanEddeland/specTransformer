function constantToSTL(obj, component)
%CONSTANTTOSTL Generates STL formula from the current component
%

bugfix = get(component); %#ok<NASGU> % Bugfix
blockName = get(component,'Value');
blockValue = evalin('base',blockName);

if strfind(blockName,'.')
    if isempty(regexp(blockName,'\d\.\d', 'once'))
        blockName = strrep(blockName,'.','_');
    end
end

% Create parameters to updateSubStructAndFormulaString
updateStruct = struct();
updateStruct.startDelay = 0;
updateStruct.endDelay = 0;
updateStruct.depth = 0;
updateStruct.modalDepth = 0;
updateStruct.type = 'signal_exp';
updateStruct.component = component;

FPIstruct = struct();
FPIstruct.prereqSignals = {};
FPIstruct.prereqFormula = '';

try
    eval(['tmp = ' blockName ';']);
    if strcmp(blockName,'true')
        % The STL formula for this will be "inf>0" (fixed by Breach at
        % creation of the STL formula)
        % This means that the type should be 'phi_exp', since it is a
        % predicate
        updateStruct.type = 'phi_exp';
        
        FPIstruct.formula = blockName;
        updateStruct.FPIstruct = FPIstruct;
        obj.updateSubStructAndFormulaString(updateStruct);
    elseif strcmp(blockName, 'false')
        % The STL formula for this will be "inf<0" (fixed by Breach at
        % creation of the STL formula)
        % This means that the type should be 'phi_exp', since it is a
        % predicate
        updateStruct.type = 'phi_exp';
        
        FPIstruct.formula = blockName;
        updateStruct.FPIstruct = FPIstruct;
        obj.updateSubStructAndFormulaString(updateStruct);
    else
        FPIstruct.formula = num2str(tmp);
        updateStruct.FPIstruct = FPIstruct;
        obj.updateSubStructAndFormulaString(updateStruct);
    end
catch
    % Fix for AUTOSAR parameters
    if isa(blockValue,'AUTOSAR.Parameter')
        if strfind(blockValue.DataType,'Enum')
            str_to_eval = ['double(' blockValue.DataType(7:end) '.' char(blockValue.Value) ')'];
            blockValue = evalin('base',str_to_eval);
        elseif strcmp(blockValue.DataType,'single') ...
                || strcmp(blockValue.DataType, 'boolean')
            blockValue = blockValue.Value;
        end
        
    end
    
    if regexp(blockName,'\d.\d')
        FPIstruct.formula = blockName;
        updateStruct.FPIstruct = FPIstruct;
        obj.updateSubStructAndFormulaString(updateStruct);
    else
        if strfind(blockName,'-')
            % Remove the minus sign!
            blockName = strrep(blockName,'-','');
            blockValue = -blockValue;
        end
        
        % We need to check if the constant is a vector or a scalar
        if numel(blockValue) == 1
            % The constant is a scalar
            % We can just evaluate the value of the constant and use it
            % directly in the STL formula
            FPIstruct.formula = num2str(blockValue);
            updateStruct.FPIstruct = FPIstruct;
            obj.updateSubStructAndFormulaString(updateStruct)
        else
            % The constant is actually a vector element
            % We cannot include the constant directly in our STL formula,
            % instead we view the constant as a signal
            
            % First we log the constant as a signal
            disp(['*** Logging ' blockName ' (vector-valued constant)']);
            obj.logOneBlock(component);
            
            % Now, the output of the block has the signal name
            portHandles = get(component, 'PortHandles');
            signalHandle = portHandles.Outport;
            signalName = get(signalHandle, 'Name');
            
            % The STL formula is simple, it's just "signalName[t]"
            FPIstruct.formula = [signalName '[t]'];
            updateStruct.FPIstruct = FPIstruct;
            updateStruct.setLogSignalName = 0;
            obj.updateSubStructAndFormulaString(updateStruct);
        end
    end
end

end

