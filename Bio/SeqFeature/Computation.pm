# $Id$
#
# BioPerl module for Bio::SeqFeature::Generic
#
# Cared for by mark Fiers <m.w.e.j.fiers@plant.wag-ur.nl>
#
# Copyright Ewan Birney, Mark Fiers
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::SeqFeature::Computation - Computation SeqFeature

=head1 SYNOPSIS

   $feat = new Bio::SeqFeature::Computation (
                                -start => 10, -end => 100,
				-strand => -1, -primary => 'repeat',
				-program_name => 'GeneMark',
				-program_date => '12-5-2000',
				-program_version => 'x.y',
				-database_name => 'Arabidopsis',
				-database_date => '12-dec-2000',
				-computation_id => 2231,
				-score    => { no_score => 334 } );


=head1 DESCRIPTION

Bio::SeqFeature::Computation extends the Generic seqfeature object with
a set of computation related fields and a more flexible set of storing
more types of score and subseqfeatures. It is compatible with the Generic
SeqFeature object.

The new way of storing score values is similar to the tag structure in the 
Generic object. For storing sets of subseqfeatures the array containg the
subseqfeatures is now a hash which contains arrays of seqfeatures
Both the score and subSeqfeature methods can be called in exactly the same
way, the value's will be stored as a 'default' score or subseqfeature.

=cut

#'

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bio.perl.org/MailList.html      - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Ewan Birney, Mark Fiers

Ewan Birney E<lt>birney@sanger.ac.ukE<gt>
Mark Fiers E<lt>m.w.e.j.fiers@plant.wag-ur.nlE<gt>

=head1 DEVELOPERS

This class has been written with an eye out of inheritance. The fields
the actual object hash are:

   _gsf_sub_hash  = reference to a hash containing sets of sub arrays
   _gsf_score_hash= reference to a hash for the score values

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::SeqFeature::Computation;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;
use Bio::SeqFeature::Generic;

@ISA = qw(Bio::SeqFeature::Generic);
						     
sub new {
    my ( $class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    #_gsf_sub_hash is a hash of hashes:
    %{$self->{'gsf_sub_hash'}} = ();
    $self->{'_gsf_score_hash'} = {};

    my ( $computation_id, $score,
	$program_name, $program_date, $program_version,
	$database_name, $database_date, $database_version) =
	    $self->_rearrange([qw(COMPUTATION_ID
				  SCORE
				  PROGRAM_NAME
				  PROGRAM_DATE
				  PROGRAM_VERSION
				  DATABASE_NAME
				  DATABASE_DATE
				  DATABASE_VERSION
				  )],@args);

    $program_name	    && $self->program_name($program_name);
    $program_date	    && $self->program_date($program_date);
    $program_version  && $self->program_version($program_version);
    $database_name    && $self->database_name($database_name);
    $database_date    && $self->database_date($database_date);
    $database_version && $self->database_version($database_version);
    $computation_id   && $self->computation_id($computation_id);
    $score            && do {
	if (ref($score)) {
	    foreach my $t ( keys %$score ) {
		$self->add_score_value($t,$score->{$t});
	    }
	} else { 	     
	    $self->score($score); 	
	}

    };
    return $self;
}  

=head2 has_score

 Title   : has_score
 Usage   : $value = $self->has_score('some_score')
 Function: Tests wether a feature contains a score
 Returns : TRUE if the SeqFeature has the score,
           and FALSE otherwise.
 Args    : The name of a score

=cut

sub has_score {
   my ($self, $score) = (shift, shift);

   return exists $self->{'_gsf_score_hash'}->{$score};
}

=head2 add_score_value

 Title   : add_score_value
 Usage   : $self->add_score_value('P_value',224);
 Returns : TRUE on success
 Args    : score (string) and value (any scalar)

=cut

sub add_score_value {
   my ($self, $score, $value) = @_;
   if ( !defined $self->{'_gsf_score_hash'}->{$score} ) {
       $self->{'_gsf_score_hash'}->{$score} = [];
   }

   push(@{$self->{'_gsf_score_hash'}->{$score}},$value);
}

=head2 score

 Title   : score
 Usage   : $value = $comp_obj->score()
           $comp_obj->score($value)
 Function: Returns the 'default' score or sets the 'default' score
           This method exist for compatibility options           
	   It would equal ($comp_obj->each_score_value('default'))[0];
 Returns : A value
 Args    : (optional) a new value for the 'default' score 

=cut

sub score {
   my ($self, $value) = (shift, shift);
   if ($value) {
      $self->add_score_value('default', $value);
   } else {
      return ($self->get_score_value('default'))[0];
   }
}

=head2 each_score_value

 Title   : each_score_value
 Usage   : @values = $gsf->each_score_value('note');
 Function: Returns a list of all the values stored
           under a particular score.
 Returns : A list of scalars
 Args    : The name of the score


=cut

sub each_score_value {
   my ($self, $score) = @_;
   if ( ! exists $self->{'_gsf_score_hash'}->{$score} ) {
       $self->throw("asking for score value that does not exist $score");
   }

   return @{$self->{'_gsf_score_hash'}->{$score}};
}


=head2 all_scores

 Title   : all_scores
 Usage   : @scores = $feat->all_scores()
 Function: Get a list of all the scores in a feature
 Returns : An array of score names
 Args    : none


=cut

sub all_scores {
   my ($self, @args) = @_;

   return keys %{$self->{'_gsf_score_hash'}};
}


=head2 remove_score

 Title   : remove_score
 Usage   : $feat->remove_score('some_score')
 Function: removes a score from this feature
 Returns : nothing
 Args    : score (string)


=cut

sub remove_score {
   my ($self, $score) = @_;

   if ( ! exists $self->{'_gsf_score_hash'}->{$score} ) {
       $self->warn("trying to remove a score that does not exist: $score");
   }

   delete $self->{'_gsf_score_hash'}->{$score};
}

=head2 computation_id

 Title   : computation_id
 Usage   : $computation_id = $feat->computation_id()
           $feat->computation_id($computation_id)
 Function: get/set on program name information
 Returns : string
 Args    : none if get, the new value if set


=cut

sub computation_id {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_computation_id'} = $value;
  }

  return $self->{'_gsf_computation_id'};
}




=head2 program_name

 Title   : program_name
 Usage   : $program_name = $feat->program_name()
           $feat->program_name($program_name)
 Function: get/set on program name information
 Returns : string
 Args    : none if get, the new value if set


=cut

sub program_name {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_program_name'} = $value;
  }

  return $self->{'_gsf_program_name'};
}

=head2 program_date

 Title   : program_date
 Usage   : $program_date = $feat->program_date()
           $feat->program_date($program_date)
 Function: get/set on program date information
 Returns : date (string)
 Args    : none if get, the new value if set


=cut

sub program_date {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_program_date'} = $value;
  }

  return $self->{'_gsf_program_date'};
}


=head2 program_version

 Title   : program_version
 Usage   : $program_version = $feat->program_version()
           $feat->program_version($program_version)
 Function: get/set on program version information
 Returns : date (string)
 Args    : none if get, the new value if set


=cut

sub program_version {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_program_version'} = $value;
  }

  return $self->{'_gsf_program_version'};
}

=head2 database_name

 Title   : database_name
 Usage   : $database_name = $feat->database_name()
           $feat->database_name($database_name)
 Function: get/set on program name information
 Returns : string
 Args    : none if get, the new value if set

=cut

sub database_name {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_database_name'} = $value;
  }

  return $self->{'_gsf_database_name'};
}

=head2 database_date

 Title   : database_date
 Usage   : $database_date = $feat->database_date()
           $feat->database_date($database_date)
 Function: get/set on program date information
 Returns : date (string)
 Args    : none if get, the new value if set


=cut

sub database_date {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_database_date'} = $value;
  }

  return $self->{'_gsf_database_date'};
}


=head2 database_version

 Title   : database_version
 Usage   : $database_version = $feat->database_version()
           $feat->database_version($database_version)
 Function: get/set on program version information
 Returns : date (string)
 Args    : none if get, the new value if set


=cut

sub database_version {
  my ($self,$value) = @_;

  if (defined($value)) {
      $self->{'_gsf_database_version'} = $value;
  }

  return $self->{'_gsf_database_version'};

}

=head2 sub_SeqFeature_type

 Title   : sub_SeqFeature_type
 Usage   : $sub_SeqFeature_type = $feat->sub_SeqFeature_type()
           $feat->sub_SeqFeature_type($sub_SeqFeature_type)
 Function: sub_SeqFeature_type is automatically set when adding
           a sub_computation (sub_SeqFeature) to a computation object
 Returns : sub_SeqFeature_type (string)
 Args    : none if get, the new value if set

=cut

sub sub_SeqFeature_type {
  my ($self, $value) = @_;

  if (defined($value)) {
      $self->{'_gsf_sub_SeqFeature_type'} = $value;
  }
  return $self->{'_gsf_sub_SeqFeature_type'};
}

=head2 all_sub_SeqFeature_types

 Title   : all_Sub_SeqFeature_types
 Usage   : @all_sub_seqfeature_types = $comp->all_Sub_SeqFeature_types();
 Function: Returns an array with all subseqfeature types
 Returns : An array
 Args    : none

=cut

sub all_sub_SeqFeature_types {
   my ($self) = @_;
   return keys ( %{$self->{'gsf_sub_hash'}} );
}

=head2 sub_SeqFeature

 Title   : sub_SeqFeature('sub_feature_type')
 Usage   : @feats = $feat->sub_SeqFeature();
           @feats = $feat->sub_SeqFeature('sub_feature_type');           
 Function: Returns an array of sub Sequence Features of a specific
           type or, if the type is ommited, all sub Sequence Features
 Returns : An array
 Args    : (optional) a sub_SeqFeature type (ie exon, pattern)

=cut

sub sub_SeqFeature {
   my ($self, $ssf_type) = @_;
   my (@return_array) = ();
   if ($ssf_type eq '') {
       #return all sub_SeqFeatures
       foreach (keys ( %{$self->{'gsf_sub_hash'}} )){
	  push @return_array, @{$self->{'gsf_sub_hash'}->{$_}};	            
       }
       return @return_array;
   } else {
       if (defined ($self->{'gsf_sub_hash'}->{$ssf_type})) {
           return @{$self->{'gsf_sub_hash'}->{$ssf_type}};	
       } else {
           $self->warn("$ssf_type is not a valid sub SeqFeature type");
       }
   }
}

=head2 add_sub_SeqFeature

 Title   : add_sub_SeqFeature
 Usage   : $feat->add_sub_SeqFeature($subfeat);
           $feat->add_sub_SeqFeature($subfeat,'sub_seqfeature_type')
           $feat->add_sub_SeqFeature($subfeat,'EXPAND')
           $feat->add_sub_SeqFeature($subfeat,'EXPAND','sub_seqfeature_type')
 Function: adds a SeqFeature into a specific subSeqFeature array.
           with no 'EXPAND' qualifer, subfeat will be tested
           as to whether it lies inside the parent, and throw
           an exception if not.
           If EXPAND is used, the parents start/end/strand will
           be adjusted so that it grows to accommodate the new
           subFeature,
	   optionally a sub_seqfeature type can be defined.
 Returns : nothing
 Args    : An object which has the SeqFeatureI interface
         : (optional) 'EXPAND'
	 : (optional) 'sub_SeqFeature_type'

=cut

sub add_sub_SeqFeature{
   my ($self,$feat,$var1, $var2) = @_;
   $var1 = '' unless( defined $var1);
   $var2 = '' unless( defined $var2);   
   my ($expand, $ssf_type) = ('', $var1 . $var2);	
   $expand = 'EXPAND' if ($ssf_type =~ s/EXPAND//);

   if ( !$feat->isa('Bio::SeqFeatureI') ) {
       $self->warn("$feat does not implement Bio::SeqFeatureI. Will add it anyway, but beware...");
   }

   if($expand eq 'EXPAND') {
       $self->_expand_region($feat);
   } else {
       if ( !$self->contains($feat) ) {
	   $self->throw("$feat is not contained within parent feature, and expansion is not valid");
       }
   }

   $ssf_type = 'default' if ($ssf_type eq '');
  
   if (!(defined ($self->{'gsf_sub_hash'}->{$ssf_type}))) {     
      @{$self->{'gsf_sub_hash'}->{$ssf_type}} = ();
   } 
   $feat->sub_SeqFeature_type($ssf_type);
   push @{$self->{'gsf_sub_hash'}->{$ssf_type}}, $feat;
}

=head2 flush_sub_SeqFeature

 Title   : flush_sub_SeqFeature
 Usage   : $sf->flush_sub_SeqFeature
           $sf->flush_sub_SeqFeature('sub_SeqFeature_type');	
 Function: Removes all sub SeqFeature or all sub SeqFeatures
 	   of a specified type 
           (if you want to remove a more specific subset, take
	    an array of them all, flush them, and add
            back only the guys you want)
 Example :
 Returns : none
 Args    : none


=cut

sub flush_sub_SeqFeature {
   my ($self, $ssf_type) = @_;
   if ($ssf_type) {
      if ((defined ($self->{'gsf_sub_hash'}->{$ssf_type}))) {   
             delete $self->{'gsf_sub_hash'}->{$ssf_type};
       } else {
           $self->warn("$ssf_type is not a valid sub SeqFeature type");
       }
   } else {
      $self->{'_gsf_sub_hash'} = {}; # zap the complete hash implicitly.
   }
} 



1;
