use v6;

#| Calculate monthly payment
#| $c = interest rate;
#| $n = mortages;
#| $L = loan value;
sub calculate-payment($c,$n,$L) is export{
    ($L*($c*(1 + $c)**$n))/((1 + $c)**$n - 1)
}

#| calculate-balance at any moment of loan
#| $c = interest rate;
#| $n = mortages;
#| $L = loan value;
# TODO tests
sub calculate-balance() is export {
    B = $L((1 + $c)**$n - (1 + $c)**$p)/((1 + $c)**$n - 1)
}

#| Converts percent to Rat
sub percent(Int $rate --> Rat) is export {
    #= 4 becomes 0.04
    Rat.new($rate,100);
}

#| Converts 12345 to 123.45 as Rat
sub money-in (Int $money --> Rat) is export {
    Rat.new($money,100);
}

#| Converts interest rate that is yearly
sub rate-monthly(Numeric $rate) is export {
    #= Due to rat is not allowing double we use 
    #= following notation 4.04% is 404
    #= $rate / hundred / percent / months om year
    Rat.new($rate,120000);
}

#| Converts percents wrote without decimal separator
sub smallrate(Int $rate --> Rat) is export {
    #= 404 becomes 0.404
    Rat.new($rate,10000);
}

#| Mother interface for all costs
class AnnualCost{
    has Int $.from;
    has Int $.to;
    method get( $loan-left,  $mortage) {!!!} 
}

#| Cost based on debt left
class AnnualCostPercentage is AnnualCost {
    has $.interest_rate;
    method get( $loan-left,  $mortage) { 
        return $loan-left*$!interest_rate;
    }
}

#| Cost based on monthly mortage installment
class AnnualCostMort is AnnualCost {
    has $.interest_rate;
    method get( $loan-left,  $mortage) {
        return $mortage*$!interest_rate;
    }
}

#| Annual cost not basing on anything just constant value
class AnnualCostConst is AnnualCost {
    has  $.value;
    method get( $loan-left,  $mortage)   {
        return $!value;
    }

}

#| Methods int this class don't round values unless specified.#|
#| Interest rates are stored in absolute value so 4% is 4/100
class Mortage {
    #TODO sparate input data from output data
    has Str $.currency; #= Currency, for gist 
    has Str $.bank; #= Bank name for gist
    has Numeric $.loan-left; #= how much debt left
    has Numeric $.interest_rate; #= Basic value for calculation of interest TODO rename to interest rate        
    has Int $.mortages; #= It is adjustable to comapare it with your bank calculations
    has Numeric $.mortage; #= The money you pay monthly without other costs 
    has Numeric $.total_interest; #= total interest paid
    has Numeric $.total_cost; #total cost, including interest
    has AnnualCost @.costs; #= Costs list included in calculation

    #| Simulation runs here. Calculates all months. 
    method calc {
        #= Results are visible in B<gist> and $.total_cost, $.loan-left
        for 1 .. $!mortages -> $mort {            
           
            for @!costs -> $cost {
                if $mort >= $cost.from && $mort <= $cost.to {
                    $!total_cost += $cost.get($.loan-left, $.mortage); 
                }                
            }
           
            #TODO rename
            my $intests =  $!interest_rate*$!loan-left;

            #say $mort, "  ",$intests.round(0.001), " ", $!loan-left.round(0.001);
            
            $!loan-left -= $!mortage;
            $!total_interest += $intests;
            $!loan-left +=  $intests;
            
        }
    }
    
    #| Provides summary with value round
    method gist {
        return join "$!currency\n", $.bank,
        "Mortage " ~ $.mortage.round(0.01),
        "Balance: " ~ $.loan-left.round(0.01),
        "Basic interests: " ~ $.total_interest.round(0.01),
        "Other costs: " ~ $.total_cost.round(0.01),
        "Total cost: " ~ ($.total_cost+$.total_interest).round(0.01);
        # if correctly calculated $.loan-left should be close to 0
    }
    
    #| Will calculate mortage only pay. Without other costs.
    #| Value is rounded!
    method calc_mortage {
            my $c = $.interest_rate;
            my $n = $.mortages;
            my $L = $.loan-left;
            my $my_mortage = calculate-payment($c,$n,$L);
            return $my_mortage.round(0.01);
    }

    #| Every cost is counted annualy so if you want to
    #| add one time cost just place it in correct month
    method add(AnnualCost $cost){
        @!costs.push($cost);
    }
    
    #| pay off debt
    method cash($cash){
        $!loan-left -= $cash;
    }
}

=begin pod
=head1 Mortage
C<Mortage> is a module that reads simulates mortage with emphasis on additional costs. 

=head1 Synopsis
    =begin code
     use Mortage;
     my $bank = Mortage.new(bank=>"BANK",interest_rate => rate-monthly(324), mortage => money-in(129093), mortages => 360, loan-left=> 297000); 
     $bank.add(AnnualCostConst.new(from=>1, to=>1, value=>$bank2.loan-left * smallrate(164))); # paid only once
     $bank.calc; # all the stuff goes here
     say $bank;
    =end code
   
=end pod

    
