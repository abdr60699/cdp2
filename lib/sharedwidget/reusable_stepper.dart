import 'package:flutter/material.dart';

class StepItem {
  final String title;
  final String? subtitle;
  final Widget? content;
  final StepState state;

  StepItem({
    required this.title,
    this.subtitle,
    this.content,
    this.state = StepState.indexed,
  });
}

class ReusableStepper extends StatelessWidget {
  final List<StepItem> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final VoidCallback? onStepContinue;
  final VoidCallback? onStepCancel;
  final StepperType type;
  final String? continueText;
  final String? cancelText;

  const ReusableStepper({
    Key? key,
    required this.steps,
    this.currentStep = 0,
    this.onStepTapped,
    this.onStepContinue,
    this.onStepCancel,
    this.type = StepperType.vertical,
    this.continueText,
    this.cancelText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stepper(
      type: type,
      currentStep: currentStep,
      onStepTapped: onStepTapped,
      onStepContinue: onStepContinue,
      onStepCancel: onStepCancel,
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: [
              if (onStepContinue != null)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(continueText ?? 'Continue'),
                ),
              const SizedBox(width: 8),
              if (onStepCancel != null)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(cancelText ?? 'Cancel'),
                ),
            ],
          ),
        );
      },
      steps: steps.map((stepItem) {
        return Step(
          title: Text(stepItem.title),
          subtitle: stepItem.subtitle != null ? Text(stepItem.subtitle!) : null,
          content: stepItem.content ?? const SizedBox.shrink(),
          state: stepItem.state,
          isActive: steps.indexOf(stepItem) == currentStep,
        );
      }).toList(),
    );
  }
}
