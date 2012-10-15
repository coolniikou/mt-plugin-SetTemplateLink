package SetTemplateLink::Plugin;

use strict;
use MT;
use Data::Dumper;

sub can_use_set {
    my $app = MT->app;
    return $app->user->is_superuser;
}


sub hdlr_set_linkedfile_templates {
    my $app = shift;
    return $app->permission_denied() unless $app->user->is_superuser;

    my $blog    = $app->blog;
    my $blog_id = $app->blog->id;
    my $plugin  = MT->component('SetTemplateLink');
    my $path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );

    return $app->error(
        $app->translate(
            "Should be set the linked path in the plugin setting.: [_1]",
            $plugin->errstr
        )
    ) if !$path;

    my $fmgr = $blog->file_mgr;
    unless ( $fmgr->exists($path) ) {
        $fmgr->mkpath($path);
    }

    if ( $fmgr->exists($path) && $fmgr->can_write($path) ) {
				my @blogs = MT::Blog->load({ id => $blog_id });
				foreach my $sibi ( @blogs ) {
						require MT::Template;
        		my @temps = MT::Template->load({ blog_id => $sibi->id });
						my $index = 1;
						my $q = $app->param;
						foreach my $temp ( @temps ) {
									#	require MT::TemplateMap;
									#	my @tempids = MT::Template->load( { text => $temp->text });
									#	$app->log( { message => "Templates :". Dumper(@tempids)});
		    		        my $template_id = $temp->id;
		    		        my $basename    = $temp->identifier . '.mtml';
		    		        my $linked_path = File::Spec->catfile( $path, $basename );
		    		        $temp->linked_file($linked_path);
										$app->log( {message => $template_id });
										#my $c = $fmgr->get_data($linked_path);
										#$temp->text($c);
										$temp->build_type(1);
		    		        $temp->save
		    		          or die $app->error(
		    		            $plugin->translate(
		    		                "Can not save template linked_file.: [_1]",
		    		                $temp->errstr
		    		            )
		    		          );

										if( $temp->build_type) {
											if ( $temp->type eq 'index' ) {
												$q->param( 'type', 'index-' . $temp->id );
												$q->param( 'tmpl_id', $temp->id );
												$q->param( 'single_template', 1 );
												require MT::CMS::Blog;
												MT::CMS::Blog::rebuild_pages($app);
											}
											elsif ( $temp->type eq 'archive'
														||	$temp->type eq 'category'
														||	$temp->type eq 'page'
														||	$temp->type eq 'individual' )
											{
												my $static_maps = delete $app->{static_dynamic_maps};
												require MT::TemplateMap;
												my $terms = { blog_id => $blog_id };

												if ( %$terms ) {
													my @maps = MT::TemplateMap->load($terms);
													my @ats = map { $_->archive_type } @maps;
													if ( $#ats >= 0 ) {
														$q->param( 'type', join(',', @ats) );
														$q->param( 'with_indexes', 1 );
														$q->param( 'no_static', 1 );
														$q->param( 'template_id', $temp->id );
														$q->param( 'single_template', 1 );
														require MT::CMS::Blog;
														MT::CMS::Blog::start_rebuild_pages($app);
													}
												};
											}
										};
										$index++;
		    		}
						$app->call_return;
				}
    }
    else {
        return $app->error(
            $app->translate(
                "Unable to create file in this path: [_1]", $path
            )
        );
    }

}


=pod
sub hdlr_set_sibling_blog_template {
		my $app = shift;
    return $app->permission_denied() unless $app->user->is_superuser;

		my $q = $app->param;
		my $blog = $app->blog;
		my $temp_id =  $q->param('id');
    my $plugin  = MT->component('SetTemplateLink');
		my @blogs = MT::Blog->load({ parent_id => $blog->parent_id,  id => { not => $blog->id } });
    my $temp = MT::Template->load( $temp_id );
		#$app->log( { message => "tem :". Dumper($temp)});
		my $root_text = $temp->text;
		my $root_identifier = $temp->identifier;
		foreach my $sib ( @blogs ) {
    		my $sibl_temp = MT::Template->load( { blog_id => $sib->id, identifier => $root_identifier  })
				or
        return $app->errtrans( 'Can\'t load template #[_1].', $sib->id );

			#	require MT::TemplateMap;

			#	my $sibl_temp_map = MT::TemplateMap->load({ template_id => $sibl_temp->id });

			#	if(!$sibl_temp_map) {
			#		require MT::CMS::Template;
			#		MT::CMS::Template::add_map($app)
			#		or
      #  	return $app->errtrans( 'Can\'t add TemplateMap #[_1].',$sib->id .' : '.  $sibl_temp->id );
			#	}

				$sibl_temp->text($root_text);
		    $sibl_temp->save
		      or die $app->error(
		        $plugin->translate(
		            "Can not save sibl_template linked_file.: [_1]",
		            $sibl_temp->errstr
		        )
		      );
		}
    $app->call_return;
}
=cut
1;
