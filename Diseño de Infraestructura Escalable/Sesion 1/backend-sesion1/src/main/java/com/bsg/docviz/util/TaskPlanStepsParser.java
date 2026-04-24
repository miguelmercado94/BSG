package com.bsg.docviz.util;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Extrae pasos numerados (1. 2) o 1) …) de un plan en texto libre. */
public final class TaskPlanStepsParser {

    private static final Pattern NUMBERED_LINE = Pattern.compile("(?m)^\\s*(\\d+)[.)\\s]+(.+?)$");

    private TaskPlanStepsParser() {}

    public static List<String> parseSteps(String planText) {
        List<String> out = new ArrayList<>();
        if (planText == null || planText.isBlank()) {
            return out;
        }
        Matcher m = NUMBERED_LINE.matcher(planText);
        while (m.find()) {
            String step = m.group(2).trim();
            if (!step.isEmpty()) {
                out.add(step);
            }
        }
        return out;
    }
}
