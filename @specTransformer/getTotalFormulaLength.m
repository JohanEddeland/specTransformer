function totalFormulaLength = getTotalFormulaLength(obj)

FPIstruct = obj.subStruct(end).FPIstruct;

totalFormulaLength = 0;
for k = 1:numel(FPIstruct)
    totalFormulaLength = totalFormulaLength + length(FPIstruct(k).prereqFormula);
    totalFormulaLength = totalFormulaLength + length(FPIstruct(k).formula);
end

end

