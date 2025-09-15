class IncentiveScheme {
  final String name;
  final String inputType; // 'percentage' or 'value'
  final String inputLabel;
  final List<IncentiveBucket> buckets;
  final bool needsTargetAndSales; // Whether this scheme needs target and sales inputs

  IncentiveScheme({
    required this.name,
    required this.inputType,
    required this.inputLabel,
    required this.buckets,
    this.needsTargetAndSales = false,
  });
}

class IncentiveBucket {
  final String condition;
  final double minValue;
  final double maxValue;
  final double incentiveAmount;

  IncentiveBucket({
    required this.condition,
    required this.minValue,
    required this.maxValue,
    required this.incentiveAmount,
  });
}

class IncentiveCalculator {
  static final List<IncentiveScheme> schemes = [
    // 1. Quarterly Cilacar M & TC Incentive
    IncentiveScheme(
      name: 'Quarterly Cilacar M & TC Incentive',
      inputType: 'percentage',
      inputLabel: '% Achievement',
      needsTargetAndSales: true,
      buckets: [
        IncentiveBucket(
          condition: '110% & above',
          minValue: 110,
          maxValue: double.infinity,
          incentiveAmount: 45000,
        ),
        IncentiveBucket(
          condition: '105% – 110%',
          minValue: 105,
          maxValue: 110,
          incentiveAmount: 40000,
        ),
        IncentiveBucket(
          condition: '100% – 105%',
          minValue: 100,
          maxValue: 105,
          incentiveAmount: 35000,
        ),
      ],
    ),
    
    // 2. Quarterly Dapacose Grp Incentive
    IncentiveScheme(
      name: 'Quarterly Dapacose Grp Incentive',
      inputType: 'percentage',
      inputLabel: '% Achievement',
      needsTargetAndSales: true,
      buckets: [
        IncentiveBucket(
          condition: '110% & above',
          minValue: 110,
          maxValue: double.infinity,
          incentiveAmount: 20000,
        ),
        IncentiveBucket(
          condition: '105% – 110%',
          minValue: 105,
          maxValue: 110,
          incentiveAmount: 15000,
        ),
        IncentiveBucket(
          condition: '100% – 105%',
          minValue: 100,
          maxValue: 105,
          incentiveAmount: 10000,
        ),
      ],
    ),
    
    // 3. Quarterly Bisotab Plain Grp Incentive
    IncentiveScheme(
      name: 'Quarterly Bisotab Plain Grp Incentive',
      inputType: 'percentage',
      inputLabel: '% Achievement',
      needsTargetAndSales: true,
      buckets: [
        IncentiveBucket(
          condition: '110% & above',
          minValue: 110,
          maxValue: double.infinity,
          incentiveAmount: 20000,
        ),
        IncentiveBucket(
          condition: '105% – 110%',
          minValue: 105,
          maxValue: 110,
          incentiveAmount: 15000,
        ),
        IncentiveBucket(
          condition: '100% – 105%',
          minValue: 100,
          maxValue: 105,
          incentiveAmount: 10000,
        ),
      ],
    ),
    
    // 4. Quarterly New Product Incentive (Bisotab T)
    IncentiveScheme(
      name: 'Quarterly New Product Incentive (Bisotab T)',
      inputType: 'value',
      inputLabel: 'PCPM Increment vs LY (₹)',
      needsTargetAndSales: false, // We'll use a special calculation for this
      buckets: [
        IncentiveBucket(
          condition: '₹20,000 & above',
          minValue: 20000,
          maxValue: double.infinity,
          incentiveAmount: 30000,
        ),
        IncentiveBucket(
          condition: '₹15,000 – ₹20,000',
          minValue: 15000,
          maxValue: 20000,
          incentiveAmount: 20000,
        ),
        IncentiveBucket(
          condition: '₹10,000 – ₹15,000',
          minValue: 10000,
          maxValue: 15000,
          incentiveAmount: 17500,
        ),
        IncentiveBucket(
          condition: '₹7,500 – ₹10,000',
          minValue: 7500,
          maxValue: 10000,
          incentiveAmount: 15000,
        ),
        IncentiveBucket(
          condition: '₹5,000 – ₹7,500',
          minValue: 5000,
          maxValue: 7500,
          incentiveAmount: 12500,
        ),
        IncentiveBucket(
          condition: '₹3,500 – ₹5,000',
          minValue: 3500,
          maxValue: 5000,
          incentiveAmount: 10000,
        ),
        IncentiveBucket(
          condition: '₹3,000 – ₹3,500',
          minValue: 3000,
          maxValue: 3500,
          incentiveAmount: 7500,
        ),
        IncentiveBucket(
          condition: '₹2,500 – ₹3,000',
          minValue: 2500,
          maxValue: 3000,
          incentiveAmount: 5000,
        ),
      ],
    ),
    
    // 5. Quarterly Total Incentive
    IncentiveScheme(
      name: 'Quarterly Total Incentive',
      inputType: 'checkbox', // Changed to checkbox type
      inputLabel: 'Quarterly Target Complete?',
      buckets: [
        IncentiveBucket(
          condition: '100% & above',
          minValue: 100,
          maxValue: double.infinity,
          incentiveAmount: 10000,
        ),
      ],
    ),
  ];

  static double calculateIncentive(IncentiveScheme scheme, double inputValue) {
    for (var bucket in scheme.buckets) {
      if (inputValue >= bucket.minValue && inputValue < bucket.maxValue) {
        return bucket.incentiveAmount;
      }
    }
    return 0.0;
  }

  static double calculateTotalIncentive(Map<String, double> incentives) {
    double total = 0;
    incentives.forEach((key, value) {
      total += value;
    });
    return total;
  }
}
