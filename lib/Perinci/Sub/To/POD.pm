package Perinci::Sub::To::POD;

use 5.010001;
use Log::Any '$log';
use Moo;

extends 'Perinci::Sub::To::FuncBase';

our $VERSION = '0.06'; # VERSION

sub BUILD {
    my ($self, $args) = @_;
}

sub _md2pod {
    require Markdown::Pod;

    my ($self, $md) = @_;
    state $m2p = Markdown::Pod->new;
    $m2p->markdown_to_pod(markdown => $md);
}

# because we need stuffs in parent's gen_doc_section_arguments() even to print
# the name, we'll just do everything in after_gen_doc().
sub after_gen_doc {
    my ($self) = @_;

    my $res   = $self->{_doc_res};
    my $meta  = $self->{_doc_meta};
    my $ometa = $self->{_doc_orig_meta};

    my $has_args = !!keys(%{$res->{args}});

    $self->add_doc_lines(
        "=head2 " . $res->{name} .
            ($has_args ? $res->{args_plterm} : "()").' -> '.$res->{human_ret},
        "");

    $self->add_doc_lines($res->{summary}.($res->{summary} =~ /\.$/ ? "":"."), "")
        if $res->{summary};

    my $examples = $meta->{examples};
    if ($examples && @$examples) {
        $self->add_doc_lines($self->loc("Examples") . ":", "");
        my $i = 0;
        for my $eg (@$examples) {
            $i++;
            my $args;
            if ($eg->{args}) {
                $args = $eg->{args};
            } elsif ($eg->{argv}) {
                require Perinci::Sub::GetArgs::Argv;
                my $gares = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
                    argv => $eg->{argv}, meta => $meta);
                die "Can't convert argv to argv in example #$i ".
                    "of function $res->{name}): $gares->[0] - $gares->[1]"
                        unless $gares->[0] == 200;
                $args = $gares->[2];
            } else {
                $args = {};
            }
            # XXX allow using language other than perl?
            require Data::Dump;
            my $argsdump = Data::Dump::dump($args);
            $argsdump =~ s/^\{\s*//; $argsdump =~ s/\s*\}\n?$//;
            my $out = "$res->{name}($argsdump);";
            my $resdump;
            if (exists $eg->{result}) {
                $resdump = Data::Dump::dump($eg->{result});
            }
            my $status = $eg->{status} // 200;
            my $comment;
            my @expl;
            $out =~ s/^/ /mg;
            # all fits on a single not-too-long line
            if ($argsdump !~ /\n/ &&
                    (!defined($resdump) || $resdump !~ /\n/) &&
                        length($argsdump) + length($resdump // "") < 80) {
                if ($status == 200) {
                    $comment = "-> $resdump" if defined $resdump;
                } else {
                    $comment = "ERROR $status";
                }
            } else {
                push @expl, "Result: C<< $resdump >>." if defined($resdump);
            }
            push @expl, ($eg->{summary} . ($eg->{summary} =~ /\.$/ ? "" : "."))
                if $eg->{summary};
            # XXX example's description

            $self->add_doc_lines(
                $out . (defined($comment) ? " # $comment" : ""),
                ("") x !!@expl,
            );
        }
    }

    $self->add_doc_lines($self->_md2pod($res->{description}), "")
        if $res->{description};

    my $feat = $meta->{features} // {};
    my @ft;
    my %spargs;
    if ($feat->{reverse}) {
        push @ft, $self->loc("This function supports reverse operation.");
        $spargs{-reverse} = {
            type => 'bool',
            summary => $self->loc("Pass -reverse=>1 to reverse operation."),
        };
    }
    # undo is deprecated now in Rinci 1.1.24+, but we still support it
    if ($feat->{undo}) {
        push @ft, $self->loc("This function supports undo operation.");
        $spargs{-undo_action} = {
            type => 'str',
            summary => $self->loc(join(
                "",
                "To undo, pass -undo_action=>'undo' to function. ",
                "You will also need to pass -undo_data. ",
                "For more details on undo protocol, ",
                "see L<Rinci::Undo>.")),
        };
        $spargs{-undo_data} = {
            type => 'array',
            summary => $self->loc(join(
                "",
                "Required if you pass -undo_action=>'undo'. ",
                "For more details on undo protocol, ",
                "see L<Rinci::function::Undo>.")),
        };
    }
    if ($feat->{dry_run}) {
        push @ft, $self->loc("This function supports dry-run operation.");
        $spargs{-dry_run} = {
            type => 'bool',
            summary=>$self->loc("Pass -dry_run=>1 to enable simulation mode."),
        };
    }
    push @ft, $self->loc("This function is pure (produce no side effects).")
        if $feat->{pure};
    push @ft, $self->loc("This function is immutable (returns same result ".
                             "for same arguments).")
        if $feat->{immutable};
    push @ft, $self->loc("This function is idempotent (repeated invocations ".
                             "with same arguments has the same effect as ".
                                 "single invocation).")
        if $feat->{idempotent};
    if ($feat->{tx}) {
        die "Sorry, I only support transaction protocol v=2"
            unless $feat->{tx}{v} == 2;
        push @ft, $self->loc("This function supports transactions.");
        $spargs{$_} = {
            type => 'str',
            summary => $self->loc(join(
                "",
                "For more information on transaction, see ",
                "L<Rinci::Transaction>.")),
        } for qw(-tx_action -tx_action_id -tx_v -tx_rollback -tx_recovery),
    }
    $self->add_doc_lines(join(" ", @ft), "", "") if @ft;

    if ($has_args) {
        $self->add_doc_lines(
            $self->loc("Arguments") .
                ' (' . $self->loc("'*' denotes required arguments") . '):',
            "",
            "=over 4",
            "",
        );
        for my $name (sort keys %{$res->{args}}) {
            my $ra = $res->{args}{$name};
            $self->add_doc_lines(join(
                "",
                "=item * B<", $name, ">",
                ($ra->{arg}{req} ? '*' : ''), ' => ',
                "I<", $ra->{human_arg}, ">",
                (defined($ra->{human_arg_default}) ?
                     " (" . $self->loc("default") .
                         ": $ra->{human_arg_default})" : "")
            ), "");
            $self->add_doc_lines(
                $ra->{summary} . ($ra->{summary} =~ /\.$/ ? "" : "."),
                "") if $ra->{summary};
            $self->add_doc_lines(
                $self->_md2pod($ra->{description}),
                "") if $ra->{description};
        }
        $self->add_doc_lines("=back", "");
    } else {
        $self->add_doc_lines($self->loc("No arguments") . ".", "");
    }

    if (keys %spargs) {
        $self->add_doc_lines(
            $self->loc("Special arguments") . ":",
            "",
            "=over 4",
            "",
        );
        for my $name (sort keys %spargs) {
            my $spa = $spargs{$name};
            $self->add_doc_lines(join(
                "",
                "=item * B<", $name, ">",
                ' => ',
                "I<", $spa->{type}, ">",
                (defined($spa->{default}) ?
                     " (" . $self->loc("default") .
                         ": $spa->{default})" : "")
            ), "");
            $self->add_doc_lines(
                $spa->{summary} . ($spa->{summary} =~ /\.$/ ? "" : "."),
                "") if $spa->{summary};
        }
        $self->add_doc_lines("=back", "");
    }

    $self->add_doc_lines($self->loc("Return value") . ':', "");
    my $rn = $ometa->{result_naked} // $meta->{result_naked};
    $self->add_doc_lines($self->_md2pod($self->loc(join(
        "",
        "Returns an enveloped result (an array). ",
        "First element (status) is an integer containing HTTP status code ",
        "(200 means OK, 4xx caller error, 5xx function error). Second element ",
        "(msg) is a string containing error message, or 'OK' if status is ",
        "200. Third element (result) is optional, the actual result. Fourth ",
        "element (meta) is called result metadata and is optional, a hash ",
        "that contains extra information."))), "")
        unless $rn;

    # XXX result summary

    # XXX result description
}

1;
# ABSTRACT: Generate POD documentation from Rinci function metadata

__END__

=pod

=encoding utf-8

=head1 NAME

Perinci::Sub::To::POD - Generate POD documentation from Rinci function metadata

=head1 VERSION

version 0.06

=head1 SYNOPSIS

You can use the included L<peri-func-doc> script, or:

 use Perinci::Sub::To::POD;
 my $doc = Perinci::Sub::To::POD->new(url => "/Some/Module/somefunc");
 say $doc->gen_doc;

=for Pod::Coverage .+

=head1 SEE ALSO

L<Perinci::To::POD> to generate POD documentation for the whole package.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DESCRIPTION

=head1 FUNCTIONS


None are exported by default, but they are exportable.

=cut
